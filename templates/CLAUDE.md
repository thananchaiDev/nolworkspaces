## Language
- สื่อสารกับผู้ใช้เป็นภาษาไทยเสมอ (ยกเว้น code, commit message, และไฟล์ .md ที่ต้องเขียนเป็นภาษาอังกฤษ)

## Design Principles
- **Single Source of Truth + DRY** — เวลาดีไซน์หรือ refactor โปรเจคใดก็ตาม ให้ logic/config/state อยู่ที่เดียว ไม่ duplicate ข้ามไฟล์ ถ้ามีหลายไฟล์ใช้ข้อมูลเดียวกัน ให้ import จากแหล่งเดียว อย่า copy (Don't Repeat Yourself)
- **SOLID** — เวลาเขียน OOP ให้ยึดหลัก SOLID เสมอ:
  - **S** Single Responsibility — class/module ทำหน้าที่เดียว
  - **O** Open/Closed — เปิดให้ extend, ปิดไม่ให้แก้ของเดิม
  - **L** Liskov Substitution — subclass แทน parent ได้เสมอโดยไม่พัง
  - **I** Interface Segregation — ไม่บังคับ implement method ที่ไม่ใช้
  - **D** Dependency Inversion — ขึ้นกับ abstraction ไม่ใช่ concrete class

## Code Reading
- **Read deeply, never skim** — when reading code, trace every function call to its actual implementation. Do not stop at variable names or function signatures and assume behavior. Follow the entire call chain to understand what really happens.
- If a function calls another function, read that inner function too. Repeat until you reach the actual logic. Surface-level reading leads to wrong conclusions.

## Debugging
- **ห้ามเดา** — ถ้าอยากรู้ behavior ของ code/library/protocol ให้เพิ่ม log/inspect เพื่อยืนยันเสมอ ห้ามเดาจากการอ่านโค้ดอย่างเดียว
- เมื่อไม่แน่ใจว่า data flow ไปถึงจุดไหน → เพิ่ม logger/interceptor ก่อนทำอย่างอื่น
- ถ้าแก้โค้ดไปแล้ว 2 ครั้งแต่ user ยังบอกว่าผิดอยู่ → หยุดเดา แล้วเพิ่ม debug log เข้าไปในโค้ดเพื่อตรวจสอบค่าจริงก่อนแก้ต่อ

## Documentation
- All `.md` files must be written in English only

## Git
- ห้ามใส่ `Co-Authored-By` ใน commit message ทุกกรณี
- Commit message ใส่แค่ title บรรทัดเดียว ไม่ต้องมี description/body

## Configuration & Constants
- **ห้าม hardcode ค่าใดๆ ในโค้ด** — ทุก config, secret, constant, URL, หรือค่าที่อาจเปลี่ยนแปลงได้ ต้องเก็บในไฟล์ config หรือ environment variable เสมอ (เช่น `.env`, `config.ts`, `constants.ts`)
- ถ้าเจอค่า hardcode ในโค้ดที่มีอยู่แล้ว ให้ย้ายออกมาก่อนทำงานต่อ

## Error Handling
- **No fallback systems** — if an operation fails, throw the error immediately. Do not implement fallback/retry/graceful-degradation patterns. If there is a problem, the error must surface so it can be diagnosed and fixed properly.

## Performance
- เมื่อมีงานที่ทำ parallel ได้ (ไม่มี dependency ระหว่างกัน) ให้ spawn agent หลายตัวพร้อมกันเสมอ เพื่อให้เสร็จเร็วที่สุด

## Frontend Aesthetics
- Avoid generic "AI slop" design. Make creative, distinctive frontends that surprise and delight.
- **Typography**: Choose beautiful, unique fonts. Avoid Inter, Roboto, Arial, system fonts. Pick distinctive fonts that elevate the aesthetic.
- **Color & Theme**: Commit to a cohesive aesthetic with CSS variables. Use dominant colors with sharp accents — avoid timid, evenly-distributed palettes. Draw from IDE themes and cultural aesthetics.
- **Motion**: Use animations for micro-interactions. Prefer CSS-only for HTML, Motion library for React. One well-orchestrated page load with staggered reveals creates more delight than scattered micro-interactions.
- **Backgrounds**: Create atmosphere and depth — layer CSS gradients, geometric patterns, or contextual effects instead of solid colors.
- **Avoid**: purple gradients on white, predictable layouts, cookie-cutter components, overused font families (Space Grotesk included).
- Vary between light/dark themes and different aesthetics per project context. Think outside the box every time.
