![Button Feedback Icon](https://raw.githubusercontent.com/ProgrammerOnCoffee/Button-Feedback/refs/heads/main/icon.png)


# Button Feedback

Button Feedback is a plugin for Godot Engine `v4.0+` that provides audiovisual
feedback to players when they interact with buttons.


## Features

- Adds sounds to buttons when they're hovered over and clicked
- Scales buttons when they're hovered over
- Removes buttons' focus stylebox when the focus is from a tap or click
- Includes three original button sounds (hover, mouse down, and mouse up)


## Installation

1. Clone or download the repository.
2. Copy the `addons/button_feedback` folder into your project.
3. Navigate to `Project > Project Settings... > Plugins` and enable Button Feedback.


## Usage

Button Feedback will automatically set up feedback for all buttons in the scene
tree when the project runs. If you create buttons or instantiate scenes during
runtime, call `ButtonFeedback.setup_button` or `ButtonFeedback.setup_recursive`.

If desired, swap out the button sounds and edit the constants in `button_feedback.gd`.


## License

This plugin is licensed under the
[MIT/Expat license](https://github.com/ProgrammerOnCoffee/Button-Feedback/blob/main/LICENSE.txt).
