# How to contribute

> All contributions to this project will be released under the CC0 public domain
> dedication. By submitting a pull request or filing a bug, issue, or
> feature request, you are agreeing to comply with this waiver of copyright interest.
> Details can be found in our [LICENCE](LICENSE).

There are two primary ways to help:

Using the Issue tracker, or
Submit a Pull Request.

## Issue tracker
Any feedback (bugs reports, feature requests, questions) is highly appreciated.
We are happy to accept your contributions to make Nakadi UI better and more awesome!
To avoid unnecessary work on either side, please stick to the following process:

1. Check if there is already an issue for your concern.
2. If there is not, [open a new one](https://github.com/zalando-incubator/nakadi-ui/issues) to start a discussion. We hate to close finished PRs!
3. If we decide your concern needs code changes, we would be happy to accept a pull request. Please consider the commit guidelines below.
In case you just want to help out and don't know where to start, issues with "help wanted" label are good for first-time contributors.

## Submit Pull Request
The code should follow any stylistic
and architectural guidelines prescribed by the project.
In the absence of such guidelines, mimic the styles and patterns in the existing code-base.
For any Elm change auto-formatting using [elm-format](https://github.com/avh4/elm-format) is mandatory.

This is a rough outline of what the workflow for code contributions looks like:
- Fork the repository on GitHub
- Create a topic branch from where you want to base your work. This is usually master.
- Make commits of logical units.
- Write good commit messages (see below).
- Push your changes to a topic branch in your fork of the repository.
- Submit a pull request to [zalando-incubator/nakadi-ui](https://github.com/zalando-incubator/nakadi-ui)
- Your pull request must receive a :thumbsup: from two [Maintainers](MAINTAINERS)

Thanks for your contributions!

### Commit messages
Your commit messages ideally should answer two questions: what changed and why.
The subject line should feature the “what” and the body of the commit should describe the “why”.
If there is already a ticket, use this number at the start of the subject line.

When creating a pull request, its comment should reference the corresponding issue id.

## Development
### Run development server
Start the development server.

```bash
npm start
```

Now you can go to `https://localhost:3000` and look at the Nakadi UI interface.

Any changes in client source code will trigger a rebuild and new files will be
automatically downloaded and applied to the browser without reload. (Hot Module Replacement).

### Run Tests

To run local end-to-end tests you need to download
[chromedriver](https://sites.google.com/a/chromium.org/chromedriver/downloads)
and place it to some `bin` directory where your os can find it.
Run `chromedriver` in a separate terminal

```bash
npm run chromedriver
```

Then run tests

```bash
npm test
```

It will run Elm tests, server unit tests, server api tests, and full end-to-end tests.
All test reports and test coverage reports will be stored in `reports` folder.

**Have fun, and happy hacking!**
