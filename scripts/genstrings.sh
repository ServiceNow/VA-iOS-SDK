cd ..
pwd

find ./ -name "*.swift" -print0 -o -name "*.m" -print0 | xargs -0 genstrings -o ./SnowChat/en.lproj