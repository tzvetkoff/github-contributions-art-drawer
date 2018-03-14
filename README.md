# GitHub Contributions Art Drawer

A stupid script that draws you custom _contributions_ from a `.txt` file.

The idea is handy if you have an account that you don't use, otherwise your regular contributions will greatly affect the chart.

## Example

Sample `source.txt`:

```
|             7777      7 7            7  444 44 44  |
|             7  7      7                  4  4 4 4  |
|             7  7 7777 7 7 77777 7777 7   4  4   4  |
|             7777 7  7 7 7    7  7  7 7             |
|             7    7  7 7 7   7   7777 7             |
|             7    7  7 7 7  7    7    7             |
|             7    7777 7 7 77777 7777 7             |
```
As you may've noticed, the source is exactly 7x52, and each line is surrounded by `|`.
This is to prevent editors from stripping trailing whitespaces.

There's some validation of the input, albeit not a very good one.

Sample usage:

``` bash
./draw.rb < source.txt > script.sh
cd /path/to/my-art-repository
sh /path/to/script.sh
git push origin +master
```

You can see it in action [here](https://github.com/polizei).

## Some credits

- Original idea came from https://github.com/gelstudios/gitfiti.
- Commit messages taken from https://github.com/ngerakines/commitment.
