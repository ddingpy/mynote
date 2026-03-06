---
title: "macOS Shortcut: Insert Today's Date"
date: 2025-10-18 12:00:00 +0900
tags: [macos, shortcuts, productivity, automation]
---


## 🪄 Step 1: Open the Shortcuts App

1. On your Mac, open the **Shortcuts** app.

   * You can find it via **Spotlight Search** (press `Command (⌘) + Space` → type “Shortcuts”).
2. Click **“+”** at the top to create a **new shortcut**.
3. Give your shortcut a name — for example: **Insert Date**.

---

## 🧩 Step 2: Get the Current Date

1. In the shortcut editor, click the **search bar** on the right.
2. Search for **“Current Date”**.
3. Drag the **“Current Date”** action into your shortcut.

   * This action gets today’s date and time.

---

## 🗓️ Step 3: Format the Date

1. In the search bar, look for **“Format Date”**.
2. Drag **“Format Date”** below **“Current Date.”**
3. Click the **little arrow** next to “Format Date” to customize it.

   * Choose **Custom Format**.
   * Type one of these formats:

     * `yyyy-MM-dd` → → **2025-10-18**
     * `MMMM d, yyyy` → → **October 18, 2025**
     * `EEE, MMM d, yyyy` → → **Sat, Oct 18, 2025**
   * (You can adjust it however you like.)

This step makes the date look exactly the way you want when it’s inserted.

---

## 💬 Step 4: Insert the Date into the Active Text Field

Now we need to “type” the formatted date wherever your cursor is.

### Option A — Use AppleScript (Recommended)

1. In the search bar, find **“Run AppleScript”**.
2. Drag it **below “Format Date.”**
3. Delete the placeholder script and paste this code:

```applescript
on run {input, parameters}
	tell application "System Events"
		keystroke (item 1 of input)
	end tell
	return input
end run
```

4. Connect the output of **“Format Date”** to **“Run AppleScript.”**

💡 What this does:

* It sends the formatted date as keystrokes (like typing) to wherever your cursor is — Notes, Safari, etc.

---

## ⚙️ Step 5: Allow Automation Control

Before the shortcut can type for you:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**.
2. Click the **“+”** and add **Shortcuts.app** if it’s not already there.
3. Make sure it’s toggled **ON** (so it can control your Mac to type text).

---

## ⌨️ Step 6: Assign a Global Keyboard Shortcut

1. Go back to your shortcut.
2. Click the **“i” (Info)** button at the top right of the Shortcut window.
3. Turn ON **“Use as Quick Action.”**
4. In “Workflow Receives,” choose **“no input”** in **“any application.”**
5. Close the info panel.
6. Now go to **System Settings → Keyboard → Keyboard Shortcuts → Services**.
7. Scroll until you find your shortcut under the **“General”** section.
8. Assign it a key combination — for example:

   * `Control + Option + D`
   * `Command + Shift + D`

Now you can press that shortcut **anywhere** to insert today’s date!

---

## 🧠 Step 7: Test Your Shortcut

1. Open any app with a text field (like Notes or TextEdit).
2. Click where you want the date.
3. Press your chosen shortcut key (e.g., `Control + Option + D`).
4. The current date should appear instantly! 🎉

---

## 🧰 Troubleshooting Tips

### ❌ The Shortcut Doesn’t Type Anything

* Go to **System Settings → Privacy & Security → Accessibility** and make sure **Shortcuts** has permission.
* Try running the shortcut directly in the **Shortcuts app** to see if it produces the date correctly.
* If the date appears in the preview but doesn’t type in the app, try **adding a short delay** before keystrokes:

  * Insert an action **“Wait”** for 0.2 seconds before “Run AppleScript.”

### 🕒 Wrong Date Format?

* Double-check your **“Format Date”** settings — ensure it’s using **Custom Format** and the right letters (`yyyy`, `MM`, `dd`, etc.).

  * `MM` = month (two digits)
  * `MMM` = month name short (e.g., Oct)
  * `MMMM` = full month (e.g., October)

### ⚡ Shortcut Not Triggering with Keys

* Go to **System Settings → Keyboard → Keyboard Shortcuts → Services** and make sure your key combo isn’t used by another shortcut.
* Restart your Mac if it still doesn’t show up.

---

## 🎯 Optional: Insert Date with Time

If you want to include the current time:

1. In **“Format Date”**, use this custom format:
   `yyyy-MM-dd HH:mm` → → **2025-10-18 14:30**
2. Everything else stays the same.

---

Would you like me to show an example **screenshot layout of how the shortcut should look** (with each block in order)?
I can describe or visualize the full Shortcut structure clearly if you want that next.
