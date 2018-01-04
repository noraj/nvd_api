# Contributing

We love contributions from everyone.
By participating in this project,
you agree to abide by the [thoughtbot][covenant] code of conduct and the [covenant][covenant] code of conduct.

  [thoughtbot]: https://thoughtbot.com/open-source-code-of-conduct
  [covenant]: https://www.contributor-covenant.org/

# Issue

See [bug](issue_templates/Bug.md) or [Feature proposal](issue_templates/Feature_proposal.md) issue templates.

I borrow the [issue guidelines of the YARD project](https://github.com/lsegal/yard/blob/master/CONTRIBUTING.md).

## Filing a Bug Report

If you believe you have found a bug, please include a few things in your report:

1. **A minimal reproduction of the issue.** Providing a huge blob of code is better than nothing, but providing the shortest possible set of instructions is even better. Take out any instructions or code that, when removed, have no effect on the problematic behavior. The easier your bug is to triage and diagnose, the higher up in the priority list it will go. We can do this stuff, but limited time means this may not happen immediately. Make your bug report extremely accessible and you will almost guarantee a quick fix.
2. **Your environment and relevant versions.** Please include your Ruby, nvd_feed_api, and system versions (including OS) when reporting a bug. This makes it easier to diagnose problems. If the issue or stack trace includes another library, consider also listing any dependencies that may be affecting the issue. This is where a minimal reproduction case helps a lot.
3. **Your expected result.** Tell us what you think should happen. This helps us to understand the context of your problem. Many complex features can contain ambiguous usage, and your use case may differ from the intended one. If we know your expectations, we can more easily determine if the behavior is intentional or not.

Finally, please **DO NOT** submit a report that states a feature simply "does not work" without any additional information in the report. Consider the issue from the maintainer's perspective: in order to fix your bug, we need to drill down to the broken line of code, and in order to do this, we must be able to reproduce the issue on our end to find that line of code. The easier we can do this, the quicker your bug gets fixed. Help us help you by providing as much information as you possibly can. We may not have the tools or environment to properly diagnose your issue, so your help may be required to debug the issue.

Also **consider opening a merge request** to fix the issue yourself if you can. This will likely speed up the fix time significantly.

## Asking a Question

Question or discussion about an idea are accepted.

## Asking for a Feature

Feature proposal are accepted.

Also **consider opening a merge request** to fix the issue yourself if you can. This will likely speed up the fix time significantly.

# Merge Request

See the [merge request](merge_request_templates/MR.md) template.

I borrow the [merge request guidelines of the YARD project](https://github.com/lsegal/yard/blob/master/CONTRIBUTING.md).

## Making a Change via Merge Request

If you've been working on a patch or feature that you want in nvd_feed_api, here are some tips to ensure the quickest turnaround time on getting it merged in:

1. **Keep your changes small.** If your feature is large, consider splitting it up into smaller portions and submit pull requests for each component individually. Feel free to describe this in your first MR or on the mailing list, but note that it will be much easier to review changes if they affect smaller portions of code at a time.
2. **Keep commits brief and clean**: nvd_feed_api uses Git and tries to maintain a clean repository. Please ensure that you use commit conventions to make things nice and neat both in the description and commit history. Specifically, consider squashing commits if you have partial or complete reverts of code. Each commit should provide an atomic change that moves the project forwards, not back. Any changes that only fix other parts of your MR should be hidden from the commit history.
3. **Follow our coding conventions.** nvd_feed_api uses typical Ruby source formatting, though it occasionally has minor differences with other projects you may have seen. Please look through a few files (at least the file you are editing) to ensure that you are consistent in the formatting your MR is using.
4. **Make sure you have tests.** Not all changes require tests, but if your changes involve code, you should consider adding at least one new test case for your change (and ideally a couple of tests). This will add confidence when reviewing and will make accepting the change much easier.
5. **Make sure ALL the tests pass.** nvd_feed_api has a fairly large suite of tests. Please make sure you can run all of the tests (bundle exec rake) prior to submitting your MR. Please also remember that nvd_feed_api supports a number of environments, and a number of older Ruby versions, so if you can test under these environments, that helps (but is not required). At the very least, be aware of this fact when submitting code.

If your change is large, consider opening an issue to ask a question or starting a discussion; we will be happy to have a conversation and let you know if the feature would be considered. They usually are, but it might be prudent to ask first!

## Security vulnerability disclosure

Please report suspected security vulnerabilities in private to `alexandre.zanni@europe.com`. Please do NOT create publicly viewable issues for suspected security vulnerabilities or open an issue and be sure to check the box **This issue is confidential and should only be visible to team members with at least Reporter access.**.

## Maintainers

**Interested in helping to maintain nvd_feed_api?** Email `alexandre.zanni@europe.com` for more information. Offering to be a project maintainer is an important contribution to open source software, and your work will be highly valued in the community. If you have been a contributor, consider being a member of the core team to help handle day-to-day operations, such as releases, bug fixes, and triage. You can do some of this as a non-maintainer too, but if you like this project, we can always use more hands on deck!
