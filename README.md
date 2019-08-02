# TelegramChart
![Swift version](https://img.shields.io/badge/Swift-4.2-orange.svg) 


<img src="https://github.com/AlexandrGraschenkov/TelegramChart/raw/master/logo.png" alt="Demo" width="782" />


Thanks Telegram for this competition. On first stage I didn't win anything cause of performance (`CoreGraphics` not good choice 😊). On second stage took **4 place**. There was issue on iPhone 6+ with scale transform.<br>
-> [Entry248](https://contest.dev/chart-ios/entry248) <-

---
<img src="https://github.com/AlexandrGraschenkov/TelegramChart/raw/master/screenshot_1.png" alt="Demo" width="359" /> &nbsp;
<img src="https://github.com/AlexandrGraschenkov/TelegramChart/raw/master/screenshot_2.png" alt="Demo" width="359" />

There you can find implementation of hight performance chart, with correct display chart zoom at any time(e.g. in animation). How it works?
- use `Metal` in core for draw charts
- for animation used wrapper around `CADisplayLink`
- reuse `UILabel`s
- the hardest part combine it together



As additional performance improvement: 
- move from `UILabel` to `CATextLayer`
- do not animate zero label

Now there is **no botelnecks** in chart. At least I didn't found it.

**P.S.** there is [brunch](https://github.com/AlexandrGraschenkov/TelegramChart/tree/pie) `pie` with experimental pie transition.

## Metal implementation details

- use `BaseDisplay` class for prepare render pipeline, work with buffer, switch reduced data
- all data move to `GPU` buffer in same way (`date`, `value`), no stack data preprocessing is performed
- on the GPU we perform 3 different display shader for each representation of chart
- switch to redused data: when there more that 1 data value for 1 pix, we switch to reduced data. On this data performance isn't issue, so I disabled it. Look at `reduceSwitchOffset`.

## Fixed Issues

- [x] From TG: iPhone 6+ chart exceed outside bounds (they said it crutual bug and give 4 place 😒)
- [x] Orientation change layout buttons
- [x] Day/night mode button move to header
- [ ] Selection not disappear when fast move date range of chart
- [ ] In line chart selection circles not disappear when this chart is hidden

### Summary
I get great expirience with `Metal`. Indeed `Metal` or `OpenGL` is good framework for problem like this. No need to trick around `CAShapeLayer`. It requere more time at first, but then much easier to build good architecture and great performance in future.

### Licence
The code under MIT licence. Do whatever you want.
