# Contribution guide

I appreciate your thought to contribute to open source. :heart:

> 👉 **NOTE**: Before participating, please read the [CODE OF CONDUCT](/CODE_OF_CONDUCT).
> 
> By interacting with this repository, organization, or community you agree to abide by its terms.

Feel free to take part or create a new [Discussion](/discussions)

## Feature / Bugfix / Improvement request

Feel free to [suggest a change](/issues/new), like feature / improvement or a bug fix.

> 👍 Or even better, contribute by developing it yourself. See below for more details on how to contribute.
## Developing

You need AutoHotkey v1.x https://www.autohotkey.com/ (Download > Current Version)

Simply clone the project and do some development. :wink:

The documentation for AHKv1 can be found here: https://www.autohotkey.com/docs/AutoHotkey.htm

The exe is built with compile-ahk (see [CREDITS](/CREDITS.md))

### Formatting

VSCode is used and the ahk extension does the formatting
> ⚠️ Apparently formatting has some odd bugs and therefore requires sometimes either manual formatting or a change in code to allow proper formatting of the code

### Testing

If applicable, write some tests to ensure your feature / fix works as intended.

> ⚠️ Bug fixes should always backed up by an unit test, unless it's not possible due to AHK.

To run the tests, simply execute `Tests/run-all.test.ahk` for all tests, or an individual `*.test.ahk`

### Pull Request

Before opening any pull request, be sure that the application does still work
Your Branch should start with `feature/`, e.g.: `feature/FeatureOrBugFix`

- [Fork](/fork) the Project
- Create your Feature Branch (`git checkout -b feature/FeatureOrBugFix`)
- Commit your Changes (`git commit -m 'Add some FeatureOrBugFix'`)
- Push to the Branch (`git push origin feature/FeatureOrBugFix`)
- Open a [Pull Request](/compare)
