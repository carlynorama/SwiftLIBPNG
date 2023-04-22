//
//  SwiftLIBPNG+LIBPNGDataBuilder.swift
//  
//
//  Created by Carlyn Maw on 4/21/23.
//
// Notes: Can confirm, Swift strings are NOT contiguous.
//        If you need to be able to find it again in memory you MUST allocate it yourself.
//
#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import png
import CShimPNG

extension SwiftLIBPNG {
    final class LIBPNGDataBuilder {
        static private var testKeyWord = "Software".utf8CString
        static private var testText = "Super Fancy libpng Writer Extraordinaire.".utf8CString
        
        //libpng functions need these to be optional.
        //can force unwrap pointers in local code b/c if they are ever nil
        //there is a much bigger problem.
        private var _ptr: png_structp?
        private var _infoPtr: png_infop?
        
        private var _pixelDataBase:UnsafeMutablePointer<UInt8>? //to dealloc
        private var _pixelDataByteCount:Int
        private var _rowPointers:[Optional<UnsafeMutablePointer<UInt8>>]? //do not need to be deallocated b/c not allocated.
        
        //TODO: Trying to avoid saving as a pointer, failed
        private var _textChunks:[tEXt]?
        
        private var _textStore:[UnsafeMutablePointer<Int8>]? //each item needs a dealloc, b/c each item alloced
        private var _textCChunks:[png_text]? //While, yes a C type, I believe this is on the stack.
        
        private var _data:Data = Data()
        
        
        //Really should force component initialization with init.
        public init?(ihdr:IHDR) {
            let png_optr = png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
            if png_optr == nil { return nil }
            self._ptr = png_optr.unsafelyUnwrapped
            
            
            let info_optr = png_create_info_struct(png_optr);
            if info_optr == nil {
                print("no info")
                png_destroy_write_struct(&_ptr, &_infoPtr)
                return nil
            }
            self._infoPtr = info_optr.unsafelyUnwrapped
            
            self._pixelDataByteCount = Int(ihdr.width * ihdr.height * ihdr.colorType.channelCount(bitDepth: UInt32(ihdr.bitDepth.rawValue)))
            self._pixelDataBase = UnsafeMutablePointer<UInt8>.allocate(capacity: _pixelDataByteCount)//malloc(_pixelDataByteCount).assumingMemoryBound(to: UInt8.self)
            if _pixelDataBase == nil {
                print("no room for pixel alloc")
                png_destroy_write_struct(&_ptr, &_infoPtr)
                return nil
            }
            
            
            do {
                try SwiftLIBPNG.setWriteBehavior(png_ptr: _ptr, bufferPointer: &self._data, write_callback: SwiftLIBPNG.LIBPNGDataBuilder.writeDataCallback, flush_callback: nil)
            }
            catch {
                png_destroy_write_struct(&_ptr, &_infoPtr)
                _pixelDataBase!.deallocate()
                print("could not set write behavior")
                return nil
            }
            
            //libpng provides accessor function to IHDR info.
            //libpng should be the source of truth.
            do {
                try SwiftLIBPNG.setIHDR(png_ptr: _ptr!, info_ptr: _infoPtr!, width: ihdr.width, height: ihdr.height, bitDepth: ihdr.bitDepth.rawValue, colorType: ihdr.colorType.rawValue)
            } catch {
                png_destroy_write_struct(&_ptr, &_infoPtr)
                _pixelDataBase!.deallocate()
                print("could not set IHDR")
                return nil
            }
        }
        
        static let writeDataCallback: @convention(c) (Optional<OpaquePointer>, Optional<UnsafeMutablePointer<UInt8>>, Int) -> Void = { png_ptr, data_io_ptr, length in
            guard let output_ptr:UnsafeMutableRawPointer = png_get_io_ptr(png_ptr) else { return }
            guard let data_ptr:UnsafeMutablePointer<UInt8> = data_io_ptr else { return }
            //print("callback io output buffer: \(output_ptr)")
            //print("callback io data buffer: \(data_ptr)")
            
            let typed_output_ptr = output_ptr.assumingMemoryBound(to: Data.self)
            typed_output_ptr.pointee.append(data_ptr, count: length)
        }
        
        //MARK: Text Chunks
        func appendTextChunk(keyword:String, value:String) {
            precondition(_textCChunks == nil) // if this has been set it's too late.
            if _textChunks == nil {
                _textChunks = [tEXt(key: keyword, value: value)]
            } else {
                _textChunks!.append(tEXt(key: keyword, value: value))
            }
        }
        
        func setTextChunks() throws {
    
            _textCChunks = []
            if _textStore == nil {
                _textStore = []
            }
            
            
            //Not entirely sure why this little hamster dance seems to be necessary
            //I would have thought that the Swift class level storage would have been
            //stable enough and pointers into _textChunks using something along
            //the lines of chunkBaseAddress + MemoryLayout<tEXt>.offset(of: \.value)
            //would have been okay, but I was not able to make that work.
            for chunk in _textChunks! {
                //TODO: Handle Null Pointer
                let keyPointer = UnsafeMutablePointer<Int8>.allocate(capacity: chunk.key_length)
                let keyBufferPtr = UnsafeMutableRawBufferPointer(start: keyPointer, count: chunk.key_length)
                chunk.key.withUnsafeBytes { bytes in
                    precondition(bytes.count == chunk.key_length)
                    for index in 0..<chunk.key_length {
                        keyBufferPtr[index] = bytes[index]
                    }
                }
                //bufferPointer has other pointer as base, do not dealloc both.
                //stow the pointer to dealloc later.
                _textStore!.append(keyPointer)
                
                
                
                //TODO: Handle Null Pointer
                let textPointer = UnsafeMutablePointer<Int8>.allocate(capacity: chunk.text_length)
                let textBufferPtr = UnsafeMutableRawBufferPointer(start: textPointer, count: chunk.text_length)
                chunk.value.withUnsafeBytes { bytes in
                    precondition(bytes.count == chunk.text_length)
                    for index in 0..<chunk.text_length {
                        textBufferPtr[index] = bytes[index]
                    }
                }
                //stow the pointer to dealloc later.
                _textStore!.append(textPointer)
                
                _textCChunks?.append(png_text(compression: chunk.compression, key: keyPointer, text: textPointer, text_length: chunk.text_length, itxt_length: 0, lang: nil, lang_key: nil))
                
            }
            
            //TODO: I think I'm just getting lucky here, that the pointers still work later.
            let count2 = LIBPNGDataBuilder.testText.count
            LIBPNGDataBuilder.testKeyWord.withUnsafeMutableBufferPointer { keywordPointer in
                LIBPNGDataBuilder.testText.withUnsafeMutableBufferPointer { textPointer in
                    _textCChunks!.append(png_text(compression: PNG_TEXT_COMPRESSION_NONE,
                                                  key: keywordPointer.baseAddress,
                                                  text: textPointer.baseAddress,
                                                  text_length: count2,
                                                  itxt_length: 0, lang: nil, lang_key: nil))
                }
            }
            
            //TODO: png_set_text mostly warns, but aborts on catastrophic memory failure, write shim
            png_set_text(_ptr, _infoPtr, _textCChunks, Int32(_textCChunks!.count))
        }
        
        func setIDAT(pixelData: [UInt8], width:UInt32, height:UInt32) throws {
            
            pixelData.withUnsafeBufferPointer { pdbp in
                //print("\(_pixelDataByteCount), \(pdbp.count)")
                precondition(_pixelDataByteCount == pdbp.count)
                _pixelDataBase!.initialize(from: pdbp.baseAddress!, count: self._pixelDataByteCount)
            }
            
            let row_byte_width = png_get_rowbytes(_ptr, _infoPtr)
            
            self._rowPointers = []
            for rowIndex in 0..<height {
                let rowStart = rowIndex * UInt32(row_byte_width)
                _rowPointers!.append(_pixelDataBase! + Int(rowStart))
            }
            //print("set rows")
            try setRows(png_ptr: _ptr, info_ptr: _infoPtr, rowPointers: &_rowPointers!)
        }
        
        func writeData() throws {
            //print("push rows")
            try pushPNGData(png_ptr: _ptr, info_ptr: _infoPtr, transforms: PNG_TRANSFORM_IDENTITY, params: nil)
            
        }
        
        func currentData() -> Data {
            //print(_data)
            return _data
        }
        
        
        deinit {
            print("deinit")
            png_destroy_write_struct(&_ptr, &_infoPtr)
            if _pixelDataBase != nil {
                _pixelDataBase!.deallocate()
            }
            if _textStore != nil {
                for pointer in _textStore! {
                    pointer.deallocate()
                }
                
            }
        }
    }
}
