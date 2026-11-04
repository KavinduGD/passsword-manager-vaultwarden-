By default the API calls are limited to 10MB. (JSON)

```
    config.temp_dir = canonicalize(CONFIG.tmp_folder()).unwrap().into();
    config.cli_colors = false; // Make sure Rocket does not color any values for logging.
    config.limits = Limits::new()
        .limit("json", 20.megabytes()) // 20MB should be enough for very large imports, something like 5000+ vault entries
        .limit("data-form", 525.megabytes()) // This needs to match the maximum allowed file size for Send
        .limit("file", 525.megabytes()); // This needs to match the maximum allowed file size for attachments

```
