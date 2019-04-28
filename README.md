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
- do not use manual draw text, it's costly operation. `UILabel` have desired cache implementation
- for animation uses `CADisplayLink`
- reuse `UILabel`s
- the hardest part combine it together



As additional performance improvement: 
- move from `UILabel` to `CATextLayer`
- do not animate zero label

Now there is **no botelnecks** in chart. At least I didn't found it.

**P.S.** there is [brunch](https://github.com/AlexandrGraschenkov/TelegramChart/tree/pie) `pie` with experimental pie transition.

### Metal implementation details

- use `BaseDisplay` class for prepare render pipeline, work with buffer, switch reduced data
- all data move to `GPU` buffer in same way (`date`, `value`), no stack data preprocessing is performed
- on the GPU we perform 3 different display shader
- switch to redused data: when there more that 1 data value for 1 pix, we switch to reduced data. On this data performance isn't issue, so I disabled it. Look at `reduceSwitchOffset`.

### Issues

- [x] From TG: iPhone 6+ chart exceed outside bounds
- [x] Orientation change layout buttons
- [x] Day/night mode button move to header
- [ ] Selection not disappear when fast move date range of chart
- [ ] In line chart selection circles not disappear when this chart is hidden

### Summary for/from me
It's good when company like Telegram perform contests like this. It's like kick for developers who forgot to grow as developer(issue solver). Business dictates to move fast. Move fast is good but sometimes to the detriment of good product. We fogot about good code or great performance. Buisness requires just do all thing fast. And support result after. Business decay grow as good developers. You need to find power inside to move forward.

I get great expirience with `Metal`. Indeed `Metal` or `OpenGL` is good framework for problem like this. No need to trick around `CAShapeLayer`. It requere more time at first, but then much easier to build good architecture and great performance in future.

### Licence
The code under MIT licence. Use it as you want.
