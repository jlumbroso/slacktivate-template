# Slacktivate Template

**UNDER CONSTRUCTION** (`slacktivate` is stable but this template is not!)

[`slacktivate`](https://github.com/jlumbroso/slacktivate) is a tool designed to programmatically manage Slack memberships.

It uses the SCIM API available on the Business+ plan of Slack, and is designed to be run from a repository.

- `input` should contain the rosters of the users to be added to Slack, in whatever format you obtain them (ground truth)
- `output` should containt the post-processes rosters, in a JSON or CSV format
- `scripts` should contain any scripts that are used to process the rosters from `input` to `output`
- `specification.yaml` should contain the rules for how the Slack should be administrated

Once this repository is configured, you can then elect to run the synchronization process as a continuous integration process, or manually.

The original application of this was to large Slacks of Princeton CS' Undergraduate Course Assistant program and Grad Student program.

## Quick Commands

This repository contains a `Makefile` that simplifies some of the core maintenance functionality.

- `make updateData`: Post-processes the CSV roster file contained in `input/` as well as the researcher JSON roster (from the [JSON feed](https://github.com/jlumbroso/princeton-scraper-cos-people)) and generates the feeds in the `output/` directory. Does not update Slack, just the local data feeds on which the Slack operations are based.

- `make slackAdd`: Run the activation, synchronization and channel update methods of `slacktivate` to update Slack memberships. No removals are done as part of this process.

- `make slackRemove`: Run the deactivation process for users that are no longer in the rosters. This is done by comparing the current Slack membership with the current rosters.

## Administration Through Slack

When using `slacktivate` to manage users, it is best to limit certain actions, while other practices are not an issue.

### Actions to avoid

- **DO NOT MANUALLY ADD USERS**, as their account might be deactivated, or their membership to channels may be altered, the next time `slacktivate` is run. Instead, it is better to understand **why** a user is being added, and then add them using the appropriate means. For instance:

  - If the user is a new grad, they should be added by uploading a new CSV roster in the correct format in the `input` directory.
  - If the user is a faculty, consider whether it is not best to simply invite the user from the CS Faculty Slack using Slack Connect.
  - If the user is a permanent guest, then add their information in the `input/guests.json` file.

- **DO NOT MANUALLY CREATE CHANNELS**, unless they are private and for a finite and distinct number of people. Instead, add the proper channel definition in the `specification.yaml` file.

- **DO NOT MANUALLY ADD AN EXISTING USER TO AN EXISTING CHANNEL**, instead add a rule to the `specification.yaml` file, such that the user in question will be assigned to the target channel.

### Actions that are okay

- It is possible to _change the topic of a channel_

- It is possible to _rename a channel_ **as long as the channel is also renamed in the `specification.yaml` file** (otherwise, a new secondary channel will be created next time `slacktivate` is run).

## Instructions

### Update for a new year

- Upload a file `input/grad-enrollments-20xx-yy-zz.csv` with the most recent roster. Should contain at least the columns (exactly as spelled):

```
"Emplid", "Cohort Year", "Degree Track", "E-Mail Address - Campus", "Student Name", "Advisor Name",
```

- Processing will involve looking up every grad student with [the COS people JSON feed](https://jlumbroso.github.io/princeton-scraper-cos-people/) based on [the department's directory](https://www.cs.princeton.edu/people) to enrich (when available) the information with a photo, detail on the research topics, the website, in general any data that is available on the public directory.

- Note: The continuous integration can be rerun when the data on the directory is updated, even if the students don't change.

### Running `slacktivate`

- After updating a roster, the first think is to validate the configuration (and roster).

```
$ pipenv run slacktivate --spec ./specification.yaml validate
1. Attempting to parse configuration file "./specification.yaml"...  DONE!
2. Processing configuration file...  DONE!

Information:
  Group definitions: 2
  Channel definitions: 5
  User source:
  - output/user-data-grad.json (type: 'json')

  User count: 252
  Group count: 11
  Channel count: 14
```

- Obtain a Slack OAuth token [as outlined in `slacktivate`'s documentation](https://github.com/jlumbroso/slacktivate#prerequisites-having-owner-access-and-getting-an-api-token).

```bash
export SLACK_TOKEN=xoxp-318776...
```

- Do a dry-run of the following operations to make sure everything is working as expected:

```bash
$ pipenv run slacktivate --spec ./specification.yaml users activate --dry-run
$ pipenv run slacktivate --spec ./specification.yaml users deactivate --dry-run
$ pipenv run slacktivate --spec ./specification.yaml users synchronize --dry-run
```

- Finally run the operations without the `--dry-run` flag.

- To create and synchronize the membership of channels, you would run (with, then without `--dry-run`):

```bash
$ pipenv run slacktivate --spec ./specification.yaml channels ensure --dry-run
```

### Update the `specification.yaml` file

The `specification.yaml` file describes how the Slack must be administrated. For instance:

```yaml
- name: "announcements"
  permissions: "admin"
  filter: "$.where($.profile.degree in ['M.S.E.', 'Ph.D.'])"

- name: "grad-fellowships-phd"
  filter: "$.where($.profile.degree in ['Ph.D.'])"
```

These two blocks create two channels, respectively #announcements and #grad-fellowships-phd. The former contains all grad students (both PhDs and MSEs) and the latter only PhDs, as specified by the filters. From this specification and the rosters, `slacktivate` will compute membership lists and determine who to invite/kick when running `channels ensure`.

## TODO

- Allow for multiple advisers (currently separated by a semicolon `;`)
