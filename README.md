# Godot Style Sheets (GSS) Plugin
A CSS-inspired Godot editor plugin for creating themes with familiar syntax

> ⚠️ **Early Development**: This is a proof-of-concept project. Features and API may change significantly.

## Overview

Godot Style Sheets (GSS) is an editor plugin that allows you to create Godot themes using CSS-like syntax. Instead of manually configuring StyleBox resources in the editor, you can write familiar CSS-style rules and generate `.theme` files automatically.

![Basic Example](https://github.com/CDcruzCode/Godot-Style-sheets/assets/88635443/dab3f518-b425-4504-b7b1-cf3a48202198)

## Features

- **Familiar CSS Syntax**: Write theme styles using CSS-like properties
- **Editor Integration**: Built-in dock panel for easy theme generation
- **File Format Support**: Works with `.gss` and `.txt` files
- **Automatic Theme Generation**: Creates `.theme` resource files ready for use in Godot
- **Modular Architecture**: Clean separation between parsing, styling, and UI components

## How It Works

1. **Install the Plugin**: Add the plugin files to your project's `addons` folder
2. **Enable the Plugin**: Activate it in Project Settings → Plugins
3. **Write GSS Styles**: Create a `.gss` or `.txt` file with your CSS-like styles
4. **Generate Theme**: Use the GSS Themer dock to select your file and generate a `.theme` resource
5. **Apply Theme**: Use the generated theme in your Godot project

## Example GSS Syntax

```css
Button {
    background-color: #4CAF50;
    border-radius: 8px;
    font-color: white;
    font-size: 16px;
    padding: 10px 20px;
}

Button:hover {
    background-color: #45a049;
}

Button:pressed {
    background-color: #3d8b40;
}
```

## Architecture

The plugin is built with a modular architecture:

- **GSSAutoload**: Main plugin class that handles the editor UI and orchestrates the workflow
- **GSSParser**: Parses GSS text into structured data
- **GSSThemer**: Converts parsed data into Godot Theme resources

## Installation

1. Copy the plugin files to your project's `addons/gss_plugin/` directory
2. Enable the plugin in Project Settings → Plugins
3. The GSS Themer dock will appear in the editor

## Current Limitations

- Limited to Button controls (more controls planned)
- Basic CSS property support
- No live preview (manual regeneration required)