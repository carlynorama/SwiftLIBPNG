//
//  File.swift
//  
//
//  Created by Labtanza on 4/21/23.
//
#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import png
import CBridgePNG

extension SwiftLIBPNG {
    final class LIBPNGDataBuilder {
        //libpng functions need these to be optional.
        //can force unwrap pointers in local code b/c if they are ever nil
        //there is a much bigger problem.
        private var _ptr: png_structp?
        private var _infoPtr: png_infop?
        
        private var _pixelDataBase:UnsafeMutablePointer<UInt8>?
        private var _pixelDataByteCount:Int
        private var _rowPointers:[Optional<UnsafeMutablePointer<UInt8>>]?
        
        private var _textChunks:[tEXt]?
        //private var _textChunksCPointer:Optional<UnsafeMutablePointer<png_text_struct>> = nil
        private var _textCChunks:[png_text]?
        
        private var _data:Data = Data()
        
        private var _miscChunkPointers:[OpaquePointer] = []
        
        static private var testKeyWord = "Software".utf8CString
        static private var testText = "This should be able to work just fine.".utf8CString
    
        
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
            self._pixelDataBase = malloc(_pixelDataByteCount).assumingMemoryBound(to: UInt8.self)
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
        
        func appendTextChunk(keyword:String, value:String) throws {
            precondition(_textCChunks == nil) // if this has been set it's too late.
            if _textChunks == nil {
                _textChunks = [tEXt(key: keyword, value: value)]
            } else {
                _textChunks!.append(tEXt(key: keyword, value: value))
            }
        }
        
        func setTextChunks() {
            //precondition(_textCChunks == nil) // if this has been set it's too late.
            _textCChunks = []
            if _textChunks != nil && _textChunks?.count ?? 0 > 0 {
                
                let count = _textChunks!.count
                
                    for index in 0..<count  {
                        withUnsafeMutableBytes(of: &_textChunks![index])  { chunkPointer in
                            let baseForIndex = chunkPointer.baseAddress!

                            let keyPointer = (baseForIndex + MemoryLayout<tEXt>.offset(of: \.key)!).assumingMemoryBound(to: Int8.self)
                            let textPointer = (baseForIndex + MemoryLayout<tEXt>.offset(of: \.value)!).assumingMemoryBound(to: Int8.self)
                        //let copy = _textChunks![index]
                        let length = (baseForIndex + MemoryLayout<tEXt>.offset(of: \.length)!).assumingMemoryBound(to: Int.self)
                        let compression = (baseForIndex + MemoryLayout<tEXt>.offset(of: \.compression)!).assumingMemoryBound(to: ForLibPNG.self)
                            print(length.pointee, keyPointer.pointee, textPointer.pointee)
                            _textCChunks?.append(png_text(compression: compression.pointee, key: keyPointer, text: textPointer, text_length: length.pointee, itxt_length: 0, lang: nil, lang_key: nil))
                    
                    }
                        
                        
                }
                
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
                
                print(_textCChunks)
                

                //TODO: Confirm this doesn't abort on failure.
                png_set_text(_ptr, _infoPtr, _textCChunks, Int32(count+1))
            }
            
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
            
        }
        
    }
}


