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
#import <MediaPlayer/MPMusicPlayerController.h>

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
NSUserDefaults* defaults;

float currentReading = 0;

float batt15 = 1.58;
float batt30 = 3.14;

int mode = 0;

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
    
    [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(updateDisplay) userInfo:Nil repeats:YES];
    
    [self.lblAFreq setText:[NSString stringWithFormat:@"%.0f MHz", frequency]];
    [self.lblBFreq setText:[NSString stringWithFormat:@"%.0f MHz", f2]];
    [self.lblCFreq setText:[NSString stringWithFormat:@"%.0f MHz", f3]];
    
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    musicPlayer.volume = 0.9;
    
    defaults = [NSUserDefaults standardUserDefaults];
    [self.btnV0 addTarget:self action:@selector(calibrate:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnV15 addTarget:self action:@selector(calibrate:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnV30 addTarget:self action:@selector(calibrate:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnO201 addTarget:self action:@selector(calibrate:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnO102 addTarget:self action:@selector(calibrate:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnO103 addTarget:self action:@selector(calibrate:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnOinf addTarget:self action:@selector(calibrate:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)calibrate:(id)sender {
    switch ([sender tag]) {
        case 1:
            [defaults setFloat:currentReading forKey:@"v15"];
            break;
        case 2:
            [defaults setFloat:currentReading forKey:@"v30"];
            break;
        case 3:
            [defaults setFloat:currentReading forKey:@"o201"];
            break;
        case 4:
            [defaults setFloat:currentReading forKey:@"o102"];
            break;
        case 5:
            [defaults setFloat:currentReading forKey:@"o103"];
            break;
        case 6:
            [defaults setFloat:currentReading forKey:@"v0"];
            break;
        case 7:
            [defaults setFloat:currentReading forKey:@"oinf"];
            break;
        
    }
}
- (IBAction)btnToggleTap:(id)sender {
if ([self.viewCalibrate isHidden]) {
  [self.viewCalibrate setHidden:NO];
} else {
    [self.viewCalibrate setHidden:YES];
}
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

    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {

         float samplingRate = wself.audioManager.samplingRate;
         for (int i=0; i < numFrames; ++i)
         {
             
                 float theta = phase * M_PI * 2;
                 float theta2 = p2 * M_PI * 2;
                 float theta3 = p3 * M_PI * 2;
                 data[i*numChannels] =  volA*sin(theta) + volB*sin(theta2);
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
    currentReading = c/20;
    
    [self.lblV0 setText:[NSString stringWithFormat:@"%.4f", [defaults floatForKey:@"v0"]]];
    [self.lblV15 setText:[NSString stringWithFormat:@"%.4f", [defaults floatForKey:@"v15"]]];
    [self.lblV30 setText:[NSString stringWithFormat:@"%.4f", [defaults floatForKey:@"v30"]]];
    [self.lblO201 setText:[NSString stringWithFormat:@"%.4f", [defaults floatForKey:@"o201"]]];
    [self.lblO102 setText:[NSString stringWithFormat:@"%.4f", [defaults floatForKey:@"o102"]]];
    [self.lblO103 setText:[NSString stringWithFormat:@"%.4f", [defaults floatForKey:@"o103"]]];
    [self.lblOinf setText:[NSString stringWithFormat:@"%.4f", [defaults floatForKey:@"oinf"]]];
    
    if (a>b*2.1) {
        mode++;
        mode = mode > 3 ? 3 : mode;
    } else {
        mode--;
        mode = mode < -3 ? -3 : mode;
    }
    
    if (mode > 0) {
        [self.lblUnit setTextColor:[UIColor greenColor]];
        [self.lblReading setTextColor:[UIColor greenColor]];
        if ([self.imgBg tag] == 1) {
            [self.imgBg setImage:[UIImage imageNamed:@"bg_volt.jpg"]];
            [self.imgBg setTag:0];
        }
        // voltmeter mode
        [self.lblUnit setText:@"V"];
        float slope = (batt30-batt15)/([defaults floatForKey:@"v30"]-[defaults floatForKey:@"v15"]);
        float zero = [defaults floatForKey:@"v15"]-(batt30-batt15)/slope;
        
        if (currentReading < [defaults floatForKey:@"v0"]*1.1) {
            [self.lblReading setText:@"0.000"];
        } else {
            [self.lblReading setText:[NSString stringWithFormat:@"%.3f", (currentReading-zero)*slope]];
        }
    } else {
        //Ω mode
        // V = 0.65 + 2.45 * 1000/(4300 + R)
        // V = 0.65 -> 0.141
        // V =
        
        [self.lblUnit setTextColor:[UIColor magentaColor]];
        [self.lblReading setTextColor:[UIColor magentaColor]];
        if ([self.imgBg tag] == 0) {
            [self.imgBg setImage:[UIImage imageNamed:@"bg_ohm.jpg"]];
            [self.imgBg setTag:1];
        }
        if (currentReading < [defaults floatForKey:@"oinf"]*1.1) {
            [self.lblReading setText:@"----"];
            [self.lblUnit setText:@"Ω"];
        } else {
            // y = -e^mx  + 1
            // 1 - y= e^mx
            // ln (1-y) = mx
            // m = ln(1-y)/x
            
            // y = 0.21 + 1000/14300
            float m;
            if (currentReading < [defaults floatForKey:@"o103"]) {
                m = 0.210 + (0.28-0.21) * pow((currentReading-[defaults floatForKey:@"oinf"]) / ([defaults floatForKey:@"o103"]-[defaults floatForKey:@"oinf"]), 0.7);
            } else if (currentReading < [defaults floatForKey:@"o102"]) {
                m = 0.280 + (0.3987-0.280) * pow((currentReading-[defaults floatForKey:@"o103"]) / ([defaults floatForKey:@"o102"]-[defaults floatForKey:@"o103"]), 0.7);
            } else {
                m = 0.3987 + (0.44255-0.3987) * pow((currentReading-[defaults floatForKey:@"o102"]) / ([defaults floatForKey:@"o201"]-[defaults floatForKey:@"o102"]), 0.58);
            }
            float ohm = 1000/(m-0.21) - 4300;
            if (ohm >= 100000) {
                [self.lblReading setText:[NSString stringWithFormat:@"%.1f", ohm/1000]];
                [self.lblUnit setText:@"kΩ"];
            } else if (ohm >= 10000) {
                [self.lblReading setText:[NSString stringWithFormat:@"%.2f", ohm/1000]];
                [self.lblUnit setText:@"kΩ"];
            } else if (ohm > 2000) {
                [self.lblReading setText:[NSString stringWithFormat:@"%.3f", ohm/1000]];
                [self.lblUnit setText:@"kΩ"];
            } else {
                [self.lblReading setText:[NSString stringWithFormat:@"%.0f", ohm > 0? ohm :0]];
                [self.lblUnit setText:@"Ω"];
            }
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    } else {
        return YES;
    }
}


@end
