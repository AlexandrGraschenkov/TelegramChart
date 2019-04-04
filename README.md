# TelegramChart
![Swift version](https://img.shields.io/badge/Swift-4.2-orange.svg) 

Thanks Telegram for this competition.

---
![example](https://github.com/AlexandrGraschenkov/TelegramChart/raw/master/example.gif)

There you can find implementation of hight performance chart, with correct display chart at any time(e.g. in animation). How it works?
- do not use manual draw text, it's costly operation. `UILabel` have desired cache implementation
- for animation uses `CADisplayLink`
- reuse `UILabel`s
- the hardest part combine it together

As additional performance improvement: 
- move from `UILabel` to `CATextLayer`
- do not animate zero label
