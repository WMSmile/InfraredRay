//
//  InfraredRayManger.swift
//  InfraredRay
//
//  Created by apple on 2017/12/28.
//  Copyright © 2017年 wumeng. All rights reserved.
//

import UIKit
import AVFoundation

class InfraredRayManger: NSObject ,AVAudioPlayerDelegate{
    
    let kNum = 0.0441  //1微妙采样的点数
    let KAmplitude = 32767
    let kFrequency = 19000
    let KSampleRate = 44100 //采样率
    var rate = 0.5;
    
    
    static let getinstance = InfraredRayManger();
    
    var player: AVAudioPlayer?

    
    
//    [8985,4481,578,555,578,555,578,555,578,555,578,555,578,555,578,555,578,555,578,1688,578,1688,578,1688,578,1688,578,1688,578,1688,578,555,578,1688,578,1688,578,555,578,1688,578,1688,578,555,578,555,578,556,578,555,578,555,578,1688,578,555,578,555,578,1688,578,1688,578,1688,578,1688,578,40734,8985,2242,578,96165]
    //MARK:- 产生红外线
    func createInfraredRay(plus:[Int]) -> Data? {

        var pcmData:Data = Data();

        for item in plus.enumerated() {
            let i = item.offset;
            print("i==\(i)");
            if (i % 2 == 0)
            {
                let allNum:Int = Int(Double(plus[i]) * kNum);
                for j in 0...allNum {
                    let dVal:Double = Double((rate * sin(2 * Double.pi * (Double(kFrequency)) * (Double(j)/44100))));

//                    let dVal:Double = rate + Double((rate * sin(2 * Double.pi * (Double(kFrequency)) * (Double(j)/44100))));
                    var val:CShort = CShort(dVal * Double(KAmplitude));
                    print("偶数 --val == \(val)");
                    let data:Data = Data.init(bytes: &val, count: MemoryLayout<CShort>.size);
                    pcmData.append(data);

                    var valMin:CShort = CShort(-val);
                    print("偶数 --valMin == \(valMin)");

                    let data1:Data = Data.init(bytes: &valMin, count: MemoryLayout<CShort>.size);
                    pcmData.append(data1);
                }
            } else{
                let allNum:Int = Int(Double(plus[i]) * kNum);
                for _ in 0...allNum {
                    let dVal:Double = 0.0;
                    var val:CShort = CShort(dVal * Double(KAmplitude));
                    print("奇数 --val == \(val)");
                    let data:Data = Data.init(bytes: &val, count: MemoryLayout<CShort>.size);
                    pcmData.append(data);

                    var valMin:CShort = CShort(-val);
                    print("奇数 --valMin == \(valMin)");

                    let data1:Data = Data.init(bytes: &valMin, count: MemoryLayout<CShort>.size);
                    pcmData.append(data1);
                }

            }

        }
        return pcmData;
    }
    
    //MARK:- 组成音频数据
    func createAudioData(plus:[Int]) -> Data? {
        let data:Data = self.createInfraredRay(plus: plus)!;
        let dataLength = data.count
        ////给音频数据添加wav头
        var wavData = Data();
        wavData.append(Data.WriteWavFileHeader(totalAudioLen: dataLength, longSampleRate: KSampleRate, channels: 2, bitsPerSample: 16));
        wavData.append(data);
        return wavData;
    }

    
    
    
    //MARK:- 发射信号
    func sendSignal(_ signalSource:[Int]) -> Void {
        //播放音频数据
        let data = self.createAudioData(plus: signalSource);
        print("data == \(String(describing: data))");
        let session = AVAudioSession()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback, with: [])
            try session.setActive(true)
            player = try! AVAudioPlayer(data: data!);
            print("歌曲长度：\(player!.duration)")
            player?.delegate = self;
            player!.play()
        } catch let err {
            print("播放失败:\(err.localizedDescription)")
        }
    }
    //MARK:- 播放结束
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("播放结束");
        self.player = nil;
    }
    
    //MARK:- 停止播放
    func stopPlay() -> Void {
        player?.stop();
    }

}

extension Data {
    /// audio wav write header
    ///
    /// - Parameters:
    ///   - totalAudioLen: data-size
    ///   - longSampleRate: SampleRate 采样率
    ///   - channels: channels 声道
    ///   - bitsPerSample: 16bit
    /// - Returns: data type
    static func WriteWavFileHeader(totalAudioLen:CLong,longSampleRate:CLong,channels:Int,bitsPerSample:CLong) -> Data {
        let bytePerSecond = longSampleRate * (bitsPerSample / 8) * channels;
        //file-size
        let totalDataLen = totalAudioLen + 44 - 8;
        var data:Data = Data.init();
        data.append([UInt8]("RIFF".utf8), count: 4);// RIFF/WAVE header
        data.append(UInt8 (totalDataLen & 0xff));//file-size (equals file-size - 8)
        data.append(UInt8 ((totalDataLen >> 8) & 0xff));
        data.append(UInt8 ((totalDataLen >> 16) & 0xff));
        data.append(UInt8 ((totalDataLen >> 24) & 0xff));
        data.append([UInt8]("WAVE".utf8), count: 4);// Mark it as type "WAVE"
        data.append([UInt8]("fmt ".utf8), count: 4);// Mark the format section "fmt " chunk
        data.append(16);// 4 bytes: size of "fmt " chunk, Length of format data.  Always 16
        data.append(0);
        data.append(0);
        data.append(0);
        data.append(1);// format = 1 ,Wave type PCM
        data.append(0);
        data.append(UInt8 (channels)); // channels
        data.append(0);
        data.append(UInt8 (longSampleRate & 0xff));
        data.append(UInt8 ((longSampleRate >> 8) & 0xff));
        data.append(UInt8 ((longSampleRate >> 16) & 0xff));
        data.append(UInt8 ((longSampleRate >> 24) & 0xff));
        data.append(UInt8 (bytePerSecond & 0xff));
        data.append(UInt8 ((bytePerSecond >> 8) & 0xff));
        data.append(UInt8 ((bytePerSecond >> 16) & 0xff));
        data.append(UInt8 ((bytePerSecond >> 24) & 0xff));
        data.append(UInt8 (channels * bitsPerSample / 8)); // block align
        data.append(0);
        data.append(UInt8(bitsPerSample)); // bits per sample
        data.append(0);
        data.append([UInt8]("data".utf8), count: 4);//"data" marker
        data.append(UInt8 (totalAudioLen & 0xff)); //data-size (equals file-size - 44).
        data.append(UInt8 ((totalAudioLen >> 8) & 0xff));
        data.append(UInt8 ((totalAudioLen >> 16) & 0xff));
        data.append(UInt8 ((totalAudioLen >> 24) & 0xff));
        return data;
    }

}
///**
// * @param sampleRate 采样率，如44100
// * @param channels 通道数，如立体声为2
// * @param bitsPerSample 采样精度，即每个采样所占数据位数，如16，表示每个采样16bit数据，即2个字节
// * @param bytePerSecond 音频数据传送速率, 单位是字节。其值为采样率×每次采样大小。播放软件利用此值可以估计缓冲区的大小。
// *                      bytePerSecond = sampleRate * (bitsPerSample / 8) * channels
// * @param fileLenIncludeHeader wav文件总数据大小，包括44字节wave文件头大小
// * @return wavHeader
// */
//private byte[] getWaveFileHeader(int sampleRate, int channels, int bitsPerSample,
//int bytePerSecond, long fileLenIncludeHeader) {
//    byte[] wavHeader = new byte[44];
//    long totalDataLen = fileLenIncludeHeader - 8;
//    long audioDataLen = totalDataLen - 36;
//
//    //ckid：4字节 RIFF 标志，大写
//    wavHeader[0]  = 'R';
//    wavHeader[1]  = 'I';
//    wavHeader[2]  = 'F';
//    wavHeader[3]  = 'F';
//
//    //cksize：4字节文件长度，这个长度不包括"RIFF"标志(4字节)和文件长度本身所占字节(4字节),即该长度等于整个文件长度 - 8
//    wavHeader[4]  = (byte)(totalDataLen & 0xff);
//    wavHeader[5]  = (byte)((totalDataLen >> 8) & 0xff);
//    wavHeader[6]  = (byte)((totalDataLen >> 16) & 0xff);
//    wavHeader[7]  = (byte)((totalDataLen >> 24) & 0xff);
//
//    //fcc type：4字节 "WAVE" 类型块标识, 大写
//    wavHeader[8]  = 'W';
//    wavHeader[9]  = 'A';
//    wavHeader[10] = 'V';
//    wavHeader[11] = 'E';
//
//    //ckid：4字节 表示"fmt" chunk的开始,此块中包括文件内部格式信息，小写, 最后一个字符是空格
//    wavHeader[12] = 'f';
//    wavHeader[13] = 'm';
//    wavHeader[14] = 't';
//    wavHeader[15] = ' ';
//
//    //cksize：4字节，文件内部格式信息数据的大小，过滤字节（一般为00000010H）
//    wavHeader[16] = 0x10;
//    wavHeader[17] = 0;
//    wavHeader[18] = 0;
//    wavHeader[19] = 0;
//
//    //FormatTag：2字节，音频数据的编码方式，1：表示是PCM 编码
//    wavHeader[20] = 1;
//    wavHeader[21] = 0;
//
//    //Channels：2字节，声道数，单声道为1，双声道为2
//    wavHeader[22] = (byte) channels;
//    wavHeader[23] = 0;
//
//    //SamplesPerSec：4字节，采样率，如44100
//    wavHeader[24] = (byte)(sampleRate & 0xff);
//    wavHeader[25] = (byte)((sampleRate >> 8) & 0xff);
//    wavHeader[26] = (byte)((sampleRate >> 16) & 0xff);
//    wavHeader[27] = (byte)((sampleRate >> 24) & 0xff);
//
//    //BytesPerSec：4字节，音频数据传送速率, 单位是字节。其值为采样率×每次采样大小。播放软件利用此值可以估计缓冲区的大小；
//    //bytePerSecond = sampleRate * (bitsPerSample / 8) * channels
//    wavHeader[28] = (byte)(bytePerSecond & 0xff);
//    wavHeader[29] = (byte)((bytePerSecond >> 8) & 0xff);
//    wavHeader[30] = (byte)((bytePerSecond >> 16) & 0xff);
//    wavHeader[31] = (byte)((bytePerSecond >> 24) & 0xff);
//
//    //BlockAlign：2字节，每次采样的大小 = 采样精度*声道数/8(单位是字节); 这也是字节对齐的最小单位, 譬如 16bit 立体声在这里的值是 4 字节。
//    //播放软件需要一次处理多个该值大小的字节数据，以便将其值用于缓冲区的调整
//    wavHeader[32] = (byte)(bitsPerSample * channels / 8);
//    wavHeader[33] = 0;
//
//    //BitsPerSample：2字节，每个声道的采样精度; 譬如 16bit 在这里的值就是16。如果有多个声道，则每个声道的采样精度大小都一样的；
//    wavHeader[34] = (byte) bitsPerSample;
//    wavHeader[35] = 0;
//
//    //ckid：4字节，数据标志符（data），表示 "data" chunk的开始。此块中包含音频数据，小写；
//    wavHeader[36] = 'd';
//    wavHeader[37] = 'a';
//    wavHeader[38] = 't';
//    wavHeader[39] = 'a';
//
//    //cksize：音频数据的长度，4字节，audioDataLen = totalDataLen - 36 = fileLenIncludeHeader - 44
//    wavHeader[40] = (byte)(audioDataLen & 0xff);
//    wavHeader[41] = (byte)((audioDataLen >> 8) & 0xff);
//    wavHeader[42] = (byte)((audioDataLen >> 16) & 0xff);
//    wavHeader[43] = (byte)((audioDataLen >> 24) & 0xff);
//    return wavHeader;
//}
//使用Objective-C
//http://www.skyfox.org/ios-audio-wav-write-header.html
//MARK:- 生成wav头文件
//NSData* WriteWavFileHeader(long totalAudioLen, long totalDataLen, long longSampleRate,int channels, long byteRate)
//{
//    Byte  header[44];
//    header[0] = 'R';  // RIFF/WAVE header
//    header[1] = 'I';
//    header[2] = 'F';
//    header[3] = 'F';
//    header[4] = (Byte) (totalDataLen & 0xff);  //file-size (equals file-size - 8)
//    header[5] = (Byte) ((totalDataLen >> 8) & 0xff);
//    header[6] = (Byte) ((totalDataLen >> 16) & 0xff);
//    header[7] = (Byte) ((totalDataLen >> 24) & 0xff);
//    header[8] = 'W';  // Mark it as type "WAVE"
//    header[9] = 'A';
//    header[10] = 'V';
//    header[11] = 'E';
//    header[12] = 'f';  // Mark the format section 'fmt ' chunk
//    header[13] = 'm';
//    header[14] = 't';
//    header[15] = ' ';
//    header[16] = 16;   // 4 bytes: size of 'fmt ' chunk, Length of format data.  Always 16
//    header[17] = 0;
//    header[18] = 0;
//    header[19] = 0;
//    header[20] = 1;  // format = 1 ,Wave type PCM
//    header[21] = 0;
//    header[22] = (Byte) channels;  // channels
//    header[23] = 0;
//    header[24] = (Byte) (longSampleRate & 0xff);
//    header[25] = (Byte) ((longSampleRate >> 8) & 0xff);
//    header[26] = (Byte) ((longSampleRate >> 16) & 0xff);
//    header[27] = (Byte) ((longSampleRate >> 24) & 0xff);
//    header[28] = (Byte) (byteRate & 0xff);
//    header[29] = (Byte) ((byteRate >> 8) & 0xff);
//    header[30] = (Byte) ((byteRate >> 16) & 0xff);
//    header[31] = (Byte) ((byteRate >> 24) & 0xff);
//    header[32] = (Byte) (2 * 16 / 8); // block align
//    header[33] = 0;
//    header[34] = 16; // bits per sample
//    header[35] = 0;
//    header[36] = 'd'; //"data" marker
//    header[37] = 'a';
//    header[38] = 't';
//    header[39] = 'a';
//    header[40] = (Byte) (totalAudioLen & 0xff);  //data-size (equals file-size - 44).
//    header[41] = (Byte) ((totalAudioLen >> 8) & 0xff);
//    header[42] = (Byte) ((totalAudioLen >> 16) & 0xff);
//    header[43] = (Byte) ((totalAudioLen >> 24) & 0xff);
//    return [[NSData alloc] initWithBytes:header length:44];;
//}
//
//
//NSData *header = WriteWavFileHeader(600,6000,16000,1,1);
//NSMutableData *wavDatas = [[NSMutableData alloc]init];
//[wavDatas appendData:header];
//[wavDatas appendData:audioData];




//http://blog.csdn.net/dfman1978/article/details/73614340
//MARK:- 定义全局变量
//#define kNum 0.0441  //1微妙采样的点数
//#define KAmplitude 32767
//#define kFrequency 19000
//#define KSampleRate 44100 //采样率
//MARK:- 生成data
//        NSMutableData *pcmData = [[NSMutableData alloc] init];
//        for(int i=0; i<num;i++){
//            if (i%2 == 0) {//如果是偶数，产生正弦波
//                int allNum = plus[i]*kNum;
//                for (int j=0; j<allNum; j++) {
//                    double dVal = 0.5+(double)(0.5*sin(2*M_PI*((double)kFrequency)*((double)j/44100)));
//                    short val = (short)(dVal*KAmplitude);
//                    NSData *data = [NSData dataWithBytes:&val length:sizeof(short)];
//                    [pcmData appendData:data];
//                    short valMin = (short)(-val);
//                    NSData *data1 = [NSData dataWithBytes:&valMin length:sizeof(short)];
//                    [pcmData appendData:data1];
//                }
//            }else{//如果是奇数，填0
//                int allNum = plus[i]*kNum;
//                for (int j=0; j<allNum; j++) {
//                    double dVal = 0.0;
//                    short shortData = (short)(dVal);
//                    NSData *data = [NSData dataWithBytes:&shortData length:sizeof(short)];
//                    [pcmData appendData:data];
//                    short shortData1 = (short)(-dVal);
//                    NSData *data1 = [NSData dataWithBytes:&shortData1 length:sizeof(short)];
//                    [pcmData appendData:data1];
//                }
//            }
//        }
//MARK:- 播放
////给音频数据添加wav头
//NSMutableData *wavData = [[NSMutableData alloc] init];
//[self addWavHead:wavData FrameSize:pcmData.length];
//[wavData appendData:pcmData];
//
////播放音频数据
//NSError *error;
//_audioPlayer = [[AVAudioPlayer alloc] initWithData:wavData error:&error];
//if (error) {
//    NSLog(@"error log is %@",error.localizedDescription);
//}else{
//    [_audioPlayer play];
//}

