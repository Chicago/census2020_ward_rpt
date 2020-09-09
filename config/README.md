# Config files


## Civis API Key

This file should contain a key for downloading from Civis' Census Intelligence Center. The name of this file is `config/civis_api_key.yaml`.

An example format for the file (with an example key):
```
key: 6bf849396360d9f2152fde6cdaab2d9f192cb9b6
```

Since a key is not available to most members of the public, this repository also contains data caches which can be used to reproduce the weekly reports. When generating the reports the appropriate `.RData` file in `./data_cache/` is loaded, which contains the data needed for that date.

If you are a platform subscriber, more info for key setup can be found here: https://civisanalytics.github.io/civis-r/

## Census API Key

The Census API key was originally included for downloading the daily response rates, but the key has not been required.

The name of the Census key file is `config/census_api_key.yaml`, and the format for that file is:

```
census_api_key: 6bf849396360d9f2152fde6cdaab2d9f192cb9b6
```

(This is also just an example)

