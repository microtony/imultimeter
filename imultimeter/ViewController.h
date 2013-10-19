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


#import <UIKit/UIKit.h>
#import "Novocaine.h"
#import "RingBuffer.h"
#import "AudioFileReader.h"
#import "AudioFileWriter.h"

@interface ViewController : UIViewController

@property (nonatomic, strong) Novocaine *audioManager;
@property (nonatomic, strong) AudioFileReader *fileReader;
@property (nonatomic, strong) AudioFileWriter *fileWriter;
@property (weak, nonatomic) IBOutlet UILabel *lblA;
@property (weak, nonatomic) IBOutlet UILabel *lblB;
@property (weak, nonatomic) IBOutlet UILabel *lblC;
@property (weak, nonatomic) IBOutlet UILabel *lblAFreq;
@property (weak, nonatomic) IBOutlet UILabel *lblBFreq;
@property (weak, nonatomic) IBOutlet UILabel *lblCFreq;
@property (weak, nonatomic) IBOutlet UILabel *lblUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblReading;
@property (weak, nonatomic) IBOutlet UIView *viewCalibrate;
@property (weak, nonatomic) IBOutlet UIButton *btnV15;
@property (weak, nonatomic) IBOutlet UIButton *btnV30;
@property (weak, nonatomic) IBOutlet UIButton *btnO201;
@property (weak, nonatomic) IBOutlet UIButton *btnO102;

@property (weak, nonatomic) IBOutlet UIButton *btnO103;
@property (weak, nonatomic) IBOutlet UILabel *lblV15;
@property (weak, nonatomic) IBOutlet UILabel *lblV30;
@property (weak, nonatomic) IBOutlet UILabel *lblO201;
@property (weak, nonatomic) IBOutlet UILabel *lblO102;
@property (weak, nonatomic) IBOutlet UILabel *lblO103;
@property (weak, nonatomic) IBOutlet UIButton *btnV0;
@property (weak, nonatomic) IBOutlet UILabel *lblV0;
@property (weak, nonatomic) IBOutlet UIButton *btnOinf;
@property (weak, nonatomic) IBOutlet UILabel *lblOinf;
@property (weak, nonatomic) IBOutlet UIButton *btnToggle;
@property (weak, nonatomic) IBOutlet UIImageView *imgBg;

@end
