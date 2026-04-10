# Infinite ListView for Flutter

[![pub package](https://img.shields.io/pub/v/bloc_infinity_list.svg)](https://pub.dev/packages/bloc_infinity_list)
[![Build Status](https://img.shields.io/github/actions/workflow/status/ristocloud-group/app-lib-bloc-infinity-list/flutter.yml)](https://github.com/ristocloud-group/app-lib-bloc-infinity-list/actions/workflows/flutter.yml)
[![Coverage Status](.github/badges/coverage-badge.svg)](https://ristocloud-group.github.io/app-lib-bloc-infinity-list/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Overview

**Infinite ListView for Flutter** is a highly customizable, concurrency-safe infinite scrolling list
widget built with the BLoC pattern.

It simplifies the creation of paginated lists in your Flutter application by managing the complex
states of fetching data (loading, loaded, errors, and exhaustion). With built-in `bloc_concurrency`
transformers, it entirely eliminates async race conditions between pull-to-refresh gestures and
scroll-to-bottom pagination requests.

## Features

- 🔄 **Race-Condition Free**: Safely handles concurrent fetch events using `restartable` and
  `droppable` transformers.
- 📜 **Two Modes**: Choose between **Automatic** (loads seamlessly as the user scrolls) and
  **Manual** (requires tapping a "Load More" button).
- 🎨 **Deeply Customizable**: Fully customize the Native `RefreshIndicator`, borders, shadows,
  margins, paddings, and loading/error states.
- ⚡ **Single Import**: Everything you need (Widgets, Blocs, Events, and States) is accessible
  through one clean import.

## Documentation

For detailed documentation, widget properties, and architecture explanations, please visit
our [Wiki](https://github.com/ristocloud-group/app-lib-bloc-infinity-list/wiki).

## Getting Started

To install and get started with `bloc_infinity_list`, follow
our [Getting Started guide](https://github.com/ristocloud-group/app-lib-bloc-infinity-list/wiki/Getting-Started)
in the Wiki.

## Examples

Check out
various [Complete Examples](https://github.com/ristocloud-group/app-lib-bloc-infinity-list/wiki/Examples)
to
see how you can easily implement both Automatic and Manual lists in your Flutter projects.

## Contributing

We welcome contributions! Please see
our [Contributing guide](https://github.com/ristocloud-group/app-lib-bloc-infinity-list/blob/main/.github/CONTRIBUTING.md)
for more information.

## License

This project is licensed under the MIT License - see
the [License](https://github.com/ristocloud-group/app-lib-bloc-infinity-list/blob/main/LICENSE) file
for details.