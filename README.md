# Reuther ArchivesSpace Reports

This ArchivesSpace plugins contains custom reports for the Walter P. Reuther Library.

## Installation

Clone this repository to `/path/to/archivesspace/plugins` and enable the plugin by editing the `/path/to/archivesspace/config/config.rb`:

```
AppConfig[:plugins] = ['reuther_aspace_reports']
```

## How it Works

This plugin adds custom reports, defined in `backend/model`, that query data according to the Reuther's guidelines. More information about adding custom reports to ArchivesSpace can be found in the [ArchivesSpace technical documentation](https://archivesspace.github.io/tech-docs/customization/reports.html).