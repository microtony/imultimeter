// Copyright (c) 2012 Alex Wiltschko
// 
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.


#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, assign) RingBuffer *ringBuffer;

@end

@implementation ViewController

float* avga;
float* avgb;
float* avgc;

float volA = 0.005;
float volB = 0.03;
float volC = 0.02;
int avgai, avgbi, avgci;

float frequency = 379.0;
float phase = 0.0;
float f2 = 3914.0;
float p2 = 0.0;
float f3 = 1025.0;
float p3 = 0.0;

- (void)dealloc
{
    delete self.ringBuffer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    avga = new float[20];
    avgb = new float[20];
    avgc = new float[20];
    avgai = avgbi = avgci = 0;
    
    [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(updateDisplay) userInfo:Nil repeats:YES];
    
    [self.lblAFreq setText:[NSString stringWithFormat:@"%.0f MHz", frequency]];
    [self.lblBFreq setText:[NSString stringWithFormat:@"%.0f MHz", f2]];
    [self.lblCFreq setText:[NSString stringWithFormat:@"%.0f MHz", f3]];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    __weak ViewController * wself = self;

    self.ringBuffer = new RingBuffer(32768, 2);
    self.audioManager = [Novocaine audioManager];

    
    // Basic playthru example
//    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
//        float volume = 0.5;
//        vDSP_vsmul(data, 1, &volume, data, 1, numFrames*numChannels);
//        wself.ringBuffer->AddNewInterleavedFloatData(data, numFrames, numChannels);
//    }];
//    
//    
//    [self.audioManager setOutputBlock:^(float *outData, UInt32 numFrames, UInt32 numChannels) {
//        wself.ringBuffer->FetchInterleavedData(outData, numFrames, numChannels);
//    }];
    
    
     // MAKE SOME NOOOOO OIIIISSSEEE
    // ==================================================
//     [self.audioManager setOutputBlock:^(float *newdata, UInt32 numFrames, UInt32 thisNumChannels)
//         {
//             for (int i = 0; i < numFrames * thisNumChannels; i++) {
//                 newdata[i] = (rand() % 100) / 100.0f / 2;
//         }
//     }];
    
    
    // MEASURE SOME DECIBELS!
    // ==================================================
    
    // SIGNAL GENERATOR!

    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {

         float samplingRate = wself.audioManager.samplingRate;
         for (int i=0; i < numFrames; ++i)
         {
             
                 float theta = phase * M_PI * 2;
                 float theta2 = p2 * M_PI * 2;
                 float theta3 = p3 * M_PI * 2;
                 data[i*numChannels ] =  volA*sin(theta) + volB*sin(theta2);
                 data[i*numChannels + 1] =  volC*sin(theta3);
                 
             phase += 1.0 / (samplingRate / frequency);
             if (phase > 1.0) phase = -1;
             p2 += 1.0 / (samplingRate / f2);
             if (p2 > 1.0) p2 = -1;
             
             p3 += 1.0 / (samplingRate / f3);
             if (p3 > 1.0) p3 = -1;
         }
     }];
    
    
    __block float* data1;
    __block float* data2;
    __block float* data3;
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        
        float samplingRate = wself.audioManager.samplingRate;
        
        int omega1 = (int)ceil(samplingRate/frequency);
        int omega2 = (int)ceil(samplingRate/f2);
        int omega3 = (int)ceil(samplingRate/f3);
        
        data1 = new float[omega1];
        data2 = new float[omega2];
        data3 = new float[omega3];
        
        for (int i=0; i<omega1; i++) data1[i] = 0;
        for (int i=0; i<omega2; i++) data2[i] = 0;
        for (int i=0; i<omega3; i++) data3[i] = 0;
        
        for (int i=0; i<numFrames; i+=numChannels) {
            double ans,q,r;
            ans = (i/numChannels) / (samplingRate / frequency);
            q = floor(ans);
            r = ans-q;
            data1[(int)(r*(samplingRate/frequency))] += data[i];
            
            ans = (i/numChannels) / (samplingRate / f2);
            q = floor(ans);
            r = ans-q;
            data2[(int)(r*(samplingRate/f2))] += data[i];

            ans = (i/numChannels) / (samplingRate / f3);
            q = floor(ans);
            r = ans-q;
            data3[(int)(r*(samplingRate/f3))] += data[i];

        }
        
        for (int i=0; i<omega1; i++) {
            data1[i] = data1[i]/(numFrames*frequency/samplingRate);
        }
        for (int i=0; i<omega2; i++) {
            data2[i] = data2[i]/(numFrames*f2/samplingRate);
        }
        for (int i=0; i<omega3; i++) {
            data3[i] = data3[i]/(numFrames*f3/samplingRate);
        }
        
        float sumsq;
        vDSP_svesq(data1,1, &sumsq, omega1);
        avga[avgai] = sqrt(sumsq/omega1);
        avgai = (avgai+1) % 20;
        vDSP_svesq(data2,1, &sumsq, omega2);
        avgb[avgbi] = sqrt(sumsq/omega2);
        avgbi = (avgbi+1) % 20;
        vDSP_svesq(data3,1, &sumsq, omega3);
        avgc[avgci] = sqrt(sumsq/omega3);
        avgci = (avgci+1) % 20;
        
        delete [] data1;
        delete [] data2;
        delete [] data3;
    }];
    
    // DALEK VOICE!
    // (aka Ring Modulator)
    
//    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         wself.ringBuffer->AddNewInterleavedFloatData(data, numFrames, numChannels);
//     }];
//    
//    __block float frequency = 100.0;
//    __block float phase = 0.0;
//    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         wself.ringBuffer->FetchInterleavedData(data, numFrames, numChannels);
//         
//         float samplingRate = wself.audioManager.samplingRate;
//         for (int i=0; i < numFrames; ++i)
//         {
//             for (int iChannel = 0; iChannel < numChannels; ++iChannel) 
//             {
//                 float theta = phase * M_PI * 2;
//                 data[i*numChannels + iChannel] *= sin(theta);
//             }
//             phase += 1.0 / (samplingRate / frequency);
//             if (phase > 1.0) phase = -1;
//         }
//     }];
//    
    
    // VOICE-MODULATED OSCILLATOR
    
//    __block float magnitude = 0.0;
//    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         vDSP_rmsqv(data, 1, &magnitude, numFrames*numChannels);
//     }];
//    
//    __block float frequency = 100.0;
//    __block float phase = 0.0;
//    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//
//         printf("Magnitude: %f\n", magnitude);
//         float samplingRate = wself.audioManager.samplingRate;
//         for (int i=0; i < numFrames; ++i)
//         {
//             for (int iChannel = 0; iChannel < numChannels; ++iChannel) 
//             {
//                 float theta = phase * M_PI * 2;
//                 data[i*numChannels + iChannel] = magnitude*sin(theta);
//             }
//             phase += 1.0 / (samplingRate / (frequency));
//             if (phase > 1.0) phase = -1;
//         }
//     }];
    
    /*
    // AUDIO FILE READING OHHH YEAHHHH
    // ========================================    
    NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:@"TLC" withExtension:@"mp3"];        

        self.fileReader = [[AudioFileReader alloc]
                           initWithAudioFileURL:inputFileURL 
                           samplingRate:self.audioManager.samplingRate
                           numChannels:self.audioManager.numOutputChannels];
    
    [self.fileReader play];
    self.fileReader.currentTime = 30.0;
    
    
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         [wself.fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
         NSLog(@"Time: %f", wself.fileReader.currentTime);
     }
     */
    // AUDIO FILE WRITING YEAH!
    // ========================================    
//    NSArray *pathComponents = [NSArray arrayWithObjects:
//                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], 
//                               @"My Recording.m4a", 
//                               nil];
//    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
//    NSLog(@"URL: %@", outputFileURL);
//    
//    self.fileWriter = [[AudioFileWriter alloc]
//                       initWithAudioFileURL:outputFileURL 
//                       samplingRate:self.audioManager.samplingRate
//                       numChannels:self.audioManager.numInputChannels];
//    
//    
//    __block int counter = 0;
//    self.audioManager.inputBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
//        [wself.fileWriter writeNewAudio:data numFrames:numFrames numChannels:numChannels];
//        counter += 1;
//        if (counter > 400) { // roughly 5 seconds of audio
//            wself.audioManager.inputBlock = nil;
//        }
//    };

    // START IT UP YO
    [self.audioManager play];

}

- (void)updateDisplay {
    float a,b,c;
    a=b=c=0;
    for (int i=0; i<20; i++) a += avga[i];
    [self.lblA setText:[NSString stringWithFormat:@"%.4f", a/20] ];
    for (int i=0; i<20; i++) b += avgb[i];
    [self.lblB setText:[NSString stringWithFormat:@"%.4f", b/20] ];
    for (int i=0; i<20; i++) c += avgc[i];
    [self.lblC setText:[NSString stringWithFormat:@"%.4f", c/20] ];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


@end
