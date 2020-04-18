# plex-storage-report
report on or remove unwanted files from *totally legitimate* content that has been downloaded via bittorrent

### installation
copy to a system which has full read/write permissions to your media storage

### configuration
see [plex-storage-report.conf](plex-storage-report.conf) or `plex-storage-report.sh -h`

### running
report mode: `plex-storage-report.sh -b /path/to/media`
delete mode: `plex-storage-report.sh -b /path/to/media -d`

example report:
```
Operating on files older than: Fri Mar 20 15:18:36 UTC 2020

+ Processing directory: /example/Movies                                                                                                                                               ++ Processing pattern: trailers ... 0B in 0 files (34 seconds)                                                                                                                      ++ Processing pattern: NFO files ... 78KiB in 63 files (36 seconds)                                                                                                                 ++ Processing pattern: compressed ZIP files ... 0B in 0 files (29 seconds)                                                                                                          ++ Processing pattern: sample files ... 566MiB in 12 files (15 seconds)                                                                                                             ++ Processing pattern: compressed RAR files ... 8.1GiB in 115 files (0 seconds)                                                                                                     Reclaimable space from /example/Movies: 8.7GiB in 190 files (114 seconds)                                                                                                                                                                                                                                                                                             + Processing directory: /example/Television                                                                                                                                           ++ Processing pattern: trailers ... 0B in 0 files (79 seconds)                                                                                                                      ++ Processing pattern: NFO files ... 411KiB in 138 files (23 seconds)                                                                                                               ++ Processing pattern: compressed ZIP files ... 0B in 0 files (23 seconds)                                                                                                          ++ Processing pattern: sample files ... 0B in 0 files (10 seconds)                                                                                                                  ++ Processing pattern: compressed RAR files ... 252GiB in 3755 files (15 seconds)                                                                                                   Reclaimable space from /example/Television: 252GiB in 3893 files (150 seconds)                                                                                                    Total reclaimable space from /example: 261GiB in 4083 files                                                                                                                                                                                                                                                                                                             4083 files waiting to be deleted, processed in 264 seconds        
```
