# Claude Gen-UI Prompts for Smart Exam Invigilation System

These prompts are specially designed to feed into Claude (or any other advanced LLM) to get high-quality, production-ready Flutter code for your application. Copy the text block below and paste it when asking Claude to improve your UI.

---

### Prompt 1: Global Design System & Theme Re-vamp
**Use this prompt when you want Claude to set up a brand new, stunning visual foundation for your app.**

> "Act as an expert Flutter UI/UX engineer. I am building a 'Smart Exam Invigilation System' with a Flutter Web frontend and a Flask (Python) backend. Right now, my UI is highly functional but visually basic. 
> 
> I need you to create a completely new, ultra-premium `AppColors` and `AppTheme` file that I can use globally. 
> 
> **Requirements:**
> 1. Use a modern, vibrant color palette (think smooth gradients between deep indigo, royal blue, and electric teal).
> 2. Implement 'Glassmorphism' principles where possible (translucency, blur backdrops, subtle borders).
> 3. Define a standard typography scale using Google Fonts (like 'Inter' or 'Outfit').
> 4. Do not remove any existing application logic; only provide the structural layout and styling classes.
> 5. Output production-ready, highly commented Dart code."

---

### Prompt 2: Redesigning the Login/Signup Pages
**Use this when you want to modernize your `login_page.dart` or `signup_page.dart`.**

> "Act as an expert level Flutter UX designer. I have a working login screen for my 'Smart Exam Invigilation System', but it looks too simple and dated.
> 
> Using the existing controllers and async functions (like `_login()`, GlobalState manipulation, and GoRouter navigation), fully redesign the `build` method.
> 
> **Aesthetic Requirements:**
> 1. Use an animated gradient or a dynamic geometric background.
> 2. The main login card should have a frosted glass effect (Glassmorphism) with `BackdropFilter`.
> 3. Inputs should have custom, modern styling (floating labels, smooth border radii, subtle focus shadows).
> 4. Ensure the UI feels like a premium SaaS or modern university portal.
> 5. **Crucial:** You must strictly preserve the `_login` function, error states, and the `context.go` routing parameters, but completely overhaul the widget tree structure to make it look breathtaking."

---

### Prompt 3: Upgrading Dashboards (Student / Teacher)
**Use this for your `teacher_home_page.dart` or `student_home_page.dart`.**

> "Act as a senior Flutter web developer specializing in rich dashboard interfaces. I need to redesign my main user dashboard for an Exam Invigilation web platform.
> 
> **Design Requirements:**
> 1. Create a sleek, modern responsive layout featuring a collapsible side-navigation menu (or a smooth top navigation bar with a frosted glass effect).
> 2. Use a dashboard card grid (`GridView` or `Wrap`) with beautiful micro-animations (e.g., subtle scaling on hover using `MouseRegion` and `AnimatedContainer`).
> 3. Implement high-quality data visualizations (or visually distinct stat cards) for things like 'Exams Scheduled', 'Live Sessions', and 'Recent Results'.
> 4. Maintain a clean, academic but modern look with plenty of whitespace and refined typography.
> 5. Do not write dummy functions for the backend data; assume I have my own controllers to fetch data, but provide a beautiful scaffold to inject this data into."

---

### Prompt 4: Overhauling the Live Monitor / Exam Execution 
**Use this for the most complex views: taking the exam or live camera monitoring.**

> "I am building a web-based exam system in Flutter. I need a specialized UI for the 'Live Exam Monitoring' dashboard (used by teachers) and the 'Exam Execution' page (used by students).
> 
> Please design a highly focused, distraction-free UI.
> 
> **For the Student View:** Provide a beautifully structured split layout where the question panel is prominently displayed on the left, and a small, floating glassmorphic camera indicator (to assure them they are being monitored) sits in the bottom right corner. Emphasize a calm, stress-reducing UI with clear progress indicators.
> 
> **For the Teacher View:** Design a grid layout to monitor multiple student camera feeds simultaneously. Make it look like a high-tech security/invigilation hub. Use status badges (e.g., 'Normal', 'Suspicious Activity') with distinct bright colors. Include a sleek sidebar for active alerts."
