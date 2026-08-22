# CCM Melodies App - Visual Guide & Screen Flow

## 🎯 **APP FLOW DIAGRAM**

```
┌─────────────────────────────────────────────────────────────┐
│                   WELCOME SCREEN                           │
│  "WELCOME TO CONNECTING CHRIST MINISTRIES"                │
│                                                             │
│        ┌─────────────────────────────────┐               │
│        │  CCM Admin Login Button (White) │               │
│        └──────────────┬──────────────────┘               │
│                       │                                   │
│        ┌──────────────▼──────────────────┐               │
│        │ Continue as Member Button       │               │
│        └──────────────┬──────────────────┘               │
│                       │                                   │
└───────────────────────┼───────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
        ▼                               ▼
   ┌─────────────┐              ┌──────────────────┐
   │  ADMIN PATH │              │  MEMBER PATH     │
   └─────────────┘              └──────────────────┘
        │                               │
        ▼                               ▼
   ┌──────────────────────┐      ┌────────────────────────┐
   │ Admin Login Screen   │      │ MainApp                │
   │ - Username field     │      │ (Member Access - No    │
   │ - Password field     │      │  Admin Features)       │
   │ - Remember Me ✓      │      │                        │
   │ - Firebase Auth      │      │                        │
   │   admin email        │      │                        │
   │   and password       │      │                        │
   └──────┬───────────────┘      └────────────┬───────────┘
          │                                   │
          │                                   │
          └───────────────┬───────────────────┘
                          │
                          ▼
              ┌───────────────────────────┐
              │     MAIN APP              │
              │  (Admin or Member)        │
              │                           │
              │ ┌─────────────────────┐  │
              │ │ BOTTOM NAVIGATION   │  │
              │ ├─────────────────────┤  │
              │ │ [HOME] SONGS MORE   │  │
              │ └─────────────────────┘  │
              └───────────────────────────┘
                        │
         ┌──────────────┼──────────────┐
         │              │              │
         ▼              ▼              ▼
    ┌────────┐    ┌─────────┐    ┌────────┐
    │  HOME  │    │  SONGS  │    │  MORE  │
    │  TAB   │    │   TAB   │    │  TAB   │
    └────────┘    └─────────┘    └────────┘
```

---

## 📱 **HOME TAB SCREEN LAYOUT**

```
┌──────────────────────────────────────────────┐
│ ☰ CONNECTING CHRIST MINISTRIES         ⊕ ✓ │ ◄─── Red AppBar
├──────────────────────────────────────────────┤
│                                              │
│  SERVICES @ CCM                              │
│  ┌──────────────────────────────────────┐   │
│  │ 🕐 First Service - Konnembattu       │   │ ◄─── Red/Blue
│  │    10:30 AM                          │   │      Gradient
│  └──────────────────────────────────────┘   │      Cards
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │ 🕐 Second Service - Samanthamallam   │   │
│  │    6:30 PM                           │   │
│  └──────────────────────────────────────┘   │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │ 🎓 Sunday School - Konnembattu       │   │
│  │    9:00 AM                           │   │
│  └──────────────────────────────────────┘   │
│                                              │
│  DAILY BREAD                        [+ Add]  │ ◄─── Admin only
│  ┌──────────────────────────────────────┐   │
│  │                                      │   │
│  │  [Bible Verse Image - if provided]   │   │ ◄─── Blue/Red
│  │                                      │   │      Gradient
│  │  "Therefore I tell you, whatever you │   │
│  │  ask for in prayer, believe that you │   │
│  │  have received it, and it will be    │   │
│  │  yours."                             │   │
│  │                                      │   │
│  │          - Matthew 21:22             │   │
│  │                                      │   │
│  │  ◀ [1 of 5] ▶                        │   │ ◄─── Navigation
│  └──────────────────────────────────────┘   │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 🎵 **SONGS TAB SCREEN LAYOUT**

```
┌──────────────────────────────────────────────┐
│ ☰ Songs                              ⊕   ✓  │ ◄─── Red AppBar
├──────────────────────────────────────────────┤
│  🔍 Search songs (Telugu or English)...      │ ◄─── Search Bar
├──────────────────────────────────────────────┤
│                                              │
│  ⭕ పాట శీర్షిక 1                           │ ◄─── Red Avatar
│  Song Title in English                       │      + Title
│  ▶                                           │      + Subtitle
│  ─────────────────────────────────────────   │
│                                              │
│  ⭕ పాట శీర్షిక 2                           │
│  Song Title in English                       │
│  ▶                                           │
│  ─────────────────────────────────────────   │
│                                              │
│  ⭕ పాట శీర్షిక 3                           │
│  Song Title in English                       │
│  ▶                                           │
│  ─────────────────────────────────────────   │
│                                              │
│                                              │
│                                              │
│                                              │
│                            ┌─────────────┐   │
│                            │ + Add Song  │   │ ◄─── Red FAB
│                            │ (Admin Only)│   │      (Admin Only)
│                            └─────────────┘   │
│                                              │
└──────────────────────────────────────────────┘
```

### **Song Details Screen (Tap on a Song)**

```
┌──────────────────────────────────────────────┐
│ ☰ Song Title in English        [−] [+]      │ ◄─── Font Size Control
├──────────────────────────────────────────────┤
│                                              │
│  పాట శీర్షిక                                 │ ◄─── Telugu Title
│  Song Title in English                       │      (Italic Subtitle)
│                                              │
│  ─────────────────────────────────────────   │
│                                              │
│  Line 1 of song lyrics...                    │
│  Line 2 of song lyrics...                    │
│  Line 3 of song lyrics...                    │
│  Line 4 of song lyrics...                    │
│  Line 5 of song lyrics...                    │
│  (Selectable text - can copy)                │
│                                              │
│  [Scrollable content]                        │
│                                              │
│                                              │
│                                              │
└──────────────────────────────────────────────┘
```

---

## ⚙️ **MORE TAB SCREEN LAYOUT**

```
┌──────────────────────────────────────────────┐
│ ☰ More                              ⊕   ✓   │ ◄─── Red AppBar
├──────────────────────────────────────────────┤
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │ ℹ️  About Us                    ▶    │   │ ◄─── Card Format
│  │     Learn more about our ministry    │   │
│  └──────────────────────────────────────┘   │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │ 👥 Pastoral Team                 ▶   │   │
│  │    Meet our pastoral leaders         │   │
│  └──────────────────────────────────────┘   │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │ ✉️  Contact Us                   ▶   │   │
│  │    Get in touch with us              │   │
│  └──────────────────────────────────────┘   │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │ ❤️  Prayer Request               ▶   │   │
│  │    Submit your prayer requests       │   │
│  └──────────────────────────────────────┘   │
│                                              │
│  ─────────────────────────────────────────   │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │  🚪 Admin Logout                     │   │ ◄─── Admin Only
│  │     (Red Background)                 │   │      (Warning Color)
│  └──────────────────────────────────────┘   │
│                                              │
└──────────────────────────────────────────────┘
```

### **Coming Soon Screen (Any Section)**

```
┌──────────────────────────────────────────────┐
│ ☰ Section Name                  ⊕   ✓       │
├──────────────────────────────────────────────┤
│                                              │
│                  [Calendar Icon]             │ ◄─── Large Icon
│                                              │
│              Coming Soon                     │ ◄─── Bold Text
│                                              │
│     This section is under development.      │
│         Check back soon!                     │
│                                              │
│                                              │
│                                              │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 🔐 **ADMIN LOGIN SCREEN**

```
┌──────────────────────────────────────────────┐
│ ☰ CCM Admin Login               ⊕   ✓       │ ◄─── Red AppBar
├──────────────────────────────────────────────┤
│                     ┌────┐                   │
│                     │🔒  │                   │ ◄─── Admin Icon
│                     └────┘                   │      in Circle
│                                              │
│                 Admin Access                 │ ◄─── Bold Red Title
│                                              │
│  [Admin Username ────────────────────────]   │
│   👤                                         │
│                                              │
│  [Admin Password ────────────────────────]   │ ◄─── Red Focus
│   🔐                                   👁️   │      Border
│                                              │
│  ☑️ Remember Me                              │ ◄─--- Remember Me
│                                              │       Checkbox
│  ┌──────────────────────────────────────┐   │
│  │          Login                       │   │ ◄─── Red Button
│  └──────────────────────────────────────┘   │
│                                              │
│          < Back to Home                      │ ◄─── Text Button
│                                              │
└──────────────────────────────────────────────┘
```

---

## 🏠 **ADD DAILY BREAD SCREEN** (Admin Only)

```
┌──────────────────────────────────────────────┐
│ ☰ Add Daily Bread               ⊕   ✓       │ ◄─── Blue AppBar
├──────────────────────────────────────────────┤
│                                              │
│  [Bible Verse ──────────────────────────]    │
│   📖 [Multiline text area]                   │ ◄─--- Blue Focus
│       ├─ Line 1                              │       Border
│       ├─ Line 2                              │
│       └─ Line 3                              │
│                                              │
│  [Bible Reference ──────────────────────]    │
│   📚 e.g., John 3:16                         │
│                                              │
│  [Image URL (Optional) ─────────────────]    │
│   🖼️  https://example.com/image.jpg          │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │      Post Daily Bread                │   │ ◄─── Blue Button
│  └──────────────────────────────────────┘   │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 🎵 **ADD SONG SCREEN** (Admin Only)

```
┌──────────────────────────────────────────────┐
│ ☰ Add New Song                  ⊕   ✓       │ ◄─── Red AppBar
├──────────────────────────────────────────────┤
│                                              │
│  [Title in English ──────────────────────]   │
│   📋 e.g., Aaradhana Neeke                   │ ◄─--- Red Focus
│                                              │       Border
│  [Title in Telugu ───────────────────────]   │
│   🌐 e.g., ఆరాధన నీకే                       │
│                                              │
│  [Song Lyrics ───────────────────────────]   │
│   🎵 [Large Multiline Text Area]             │
│       ├─ Line 1                              │
│       ├─ Line 2                              │
│       └─ Line 3                              │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │   Save & Publish Song               │   │ ◄─--- Red Button
│  └──────────────────────────────────────┘   │
│                                              │
│  [Showing circular progress if saving]      │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 🎨 **COLOR REFERENCE**

| Element | Color | Hex Code | Usage |
|---------|-------|----------|-------|
| Primary Red | Thick Red | #C41E3A | AppBars, Buttons, Headlines |
| Secondary Blue | Thick Blue | #003DA5 | Accents, Secondary Elements |
| Background | White | #FFFFFF | Page backgrounds |
| Light Background | Light Gray | #F5F5F5 | Form inputs, secondary bg |
| Text | Dark Gray | #333333 | Body text |
| Accent Borders | Red Opacity | rgba(196,30,58,0.2) | Card borders |

---

## 🔘 **BUTTON STYLES**

### **Primary Button (Red)**
```
Background: #C41E3A
Text: White Bold 16px
Padding: 14px vertical
Border Radius: 12px
Icon: Included on left
```

### **Secondary Button (Blue)**
```
Background: #003DA5
Text: White Bold 16px
Padding: 14px vertical
Border Radius: 12px
Icon: Included on left
```

### **Outline Button**
```
Background: Transparent
Border: 2px White
Text: White Bold 16px
Border Radius: 12px
Icon: Included on left
```

### **Text Button**
```
Background: Transparent
Text: Red/Blue Colored
No padding or border
Used for secondary actions
```

---

## 📐 **SPACING STANDARD**

```
Extra Small:  4px   - Between closely related elements
Small:        8px   - Standard gap between elements
Medium:       12px  - Between components
Large:        16px  - Standard horizontal padding
Extra Large:  24px  - Between major sections
Huge:         32px  - Welcome screen padding
```

---

## 🔄 **USER FLOW FOR ADMIN**

```
1. Welcome Screen
   ├─ Click "CCM Admin Login"
   │
2. Admin Login Screen
   ├─ Enter Firebase Auth admin email
   ├─ Enter Firebase Auth password
   ├─ Check "Remember Me" (optional)
   └─ Click Login
   │
3. Main App (Admin Access)
   ├─ Home Tab
   │  ├─ View Services
   │  ├─ View Daily Bread
   │  └─ Click "Add" → Add Daily Bread Screen
   │     ├─ Enter Bible Verse
   │     ├─ Enter Reference
   │     ├─ Enter Image URL
   │     └─ Click "Post Daily Bread"
   │
   ├─ Songs Tab
   │  ├─ Search Songs
   │  ├─ Tap Song to view lyrics
   │  └─ Click FAB "Add Song" → Add Song Screen
   │     ├─ Enter English Title
   │     ├─ Enter Telugu Title
   │     ├─ Enter Lyrics
   │     └─ Click "Save & Publish Song"
   │
   └─ More Tab
      ├─ View Coming Soon Sections
      ├─ (About Us, Pastoral Team, etc.)
      └─ Click "Admin Logout"
         ├─ Confirm logout
         └─ Return to Welcome Screen
```

---

## 🔄 **USER FLOW FOR MEMBER**

```
1. Welcome Screen
   ├─ Click "Continue as Member"
   │
2. Main App (Member Access)
   ├─ Home Tab
   │  ├─ View Services
   │  └─ View Daily Bread
   │     ├─ View Latest Verse
   │     └─ Navigate to Previous Verses
   │
   ├─ Songs Tab
   │  ├─ Search Songs
   │  └─ Tap Song to view lyrics
   │     ├─ Increase/Decrease Font Size
   │     └─ Select and Copy Text
   │
   └─ More Tab
      ├─ Tap "About Us" → Coming Soon
      ├─ Tap "Pastoral Team" → Coming Soon
      ├─ Tap "Contact Us" → Coming Soon
      └─ Tap "Prayer Request" → Coming Soon
         (Note: No Logout button visible)
```

---

## ✨ **VISUAL DESIGN ELEMENTS**

### **Gradient Combinations**
1. **Welcome Screen**: Red (top-left) → Blue (bottom-right)
2. **Service Cards**: Red → Blue (left to right)
3. **Daily Bread**: Blue → Red (left to right)
4. **Form Backgrounds**: Light Red/Blue opacity 0.05

### **Shadow Effects**
- Soft shadow: `color: black.opacity(0.05), blur: 4`
- Card shadow: `color: black.opacity(0.1), blur: 8`
- Used on: Cards, FAB, elevated buttons

### **Rounded Corners**
- Standard: 12px (cards, buttons, inputs)
- Small: 8px (minor elements)
- Circle: 50% (avatars, icon backgrounds)

---

**This visual guide will help you understand the complete app structure and user experience flow.**
