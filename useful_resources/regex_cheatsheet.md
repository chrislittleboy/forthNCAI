# Regex cheatsheet for R (stringr)

Examples use your survey short names, e.g. `x <- c("permit1", "p1_3_wildplantfood", "p1_10_plantenergy", "confid_ownopin")`.

## 0. The R gotcha: double backslashes

Regex writes `\d`. R strings eat one backslash, so you type `"\\d"`.
Or use a raw string, which needs no doubling: `r"(\d+)"`.
It is a **back**slash (`\`), not a forward slash (`/`).

## 1. Matching characters

| Pattern | Matches | Example |
|---|---|---|
| `abc` | the literal text | `"pollin"` finds `r2_6_pollination` |
| `.` | any one character | `"p.1"` |
| `\\.` | a literal dot | `"3\\.5"` |
| `\\d` | one digit | `"\\d"` |
| `\\D` | one non-digit | |
| `\\w` | letter, digit or `_` | |
| `\\s` | whitespace (space, tab, newline) | catches stray spaces in headers |
| `[abc]` | one of a, b or c | `"^[prc]\\d"` |
| `[a-z]` `[0-9]` | a range | `"[a-z]+"` |
| `[^0-9]` | anything except digits | |

## 2. Quantifiers (how many of the thing before)

| Pattern | Meaning |
|---|---|
| `+` | one or more: `\\d+` matches `1` and `12` |
| `*` | zero or more |
| `?` | optional (zero or one) |
| `{3}` | exactly 3 |
| `{2,4}` | between 2 and 4 |

`*` is **not** a file-style wildcard. The "match anything" wildcard is `.`, so "any characters, any number" is `.*`.
A quantifier needs something before it: a pattern starting with `*` is a syntax error.

## 3. Anchors and alternatives

| Pattern | Meaning |
|---|---|
| `^` | start of the string |
| `$` | end of the string |
| `(a\|b)` | a or b |
| `(...)` | group, and capture for `str_match()` |

`^` inside `[ ]` at the start means "not" (`[^0-9]`). Outside, it means "start of string".

## 4. Your patterns, decoded

| Pattern | Reads as |
|---|---|
| `^p\\d+_` | starts with p, digits, underscore (not `permit1`) |
| `^[prc]\\d+_\\d+_` | any service column: letter, group no., underscore, item no., underscore |
| `^\\d+\\. ` | Jisc header starting "12. " |
| `_\\d+_` | digits between two underscores |

## 5. stringr functions (pattern is always the 2nd argument)

| Function | Returns | Use it to |
|---|---|---|
| `str_detect(x, p)` | TRUE/FALSE per string | `filter()` rows |
| `str_subset(x, p)` | the strings that match | get column names for a group |
| `str_extract(x, p)` | the matched part (NA if none) | pull out a number |
| `str_match(x, p)` | matrix: whole match + each `( )` group | split into parts |
| `str_replace(x, p, new)` | strings with 1st match replaced | tidy text |
| `str_replace_all(x, p, new)` | all matches replaced | remove all spaces |
| `str_count(x, p)` | number of matches | |
| `str_view(x, p)` | highlights matches in the console | **test patterns here** |

`lapply` pairing: `lapply(patterns, \(p) str_subset(codebook$short, p))`.

### Worked examples

```r
str_extract(x, "\\d+")                    # first run of digits
str_extract(x, "^[a-z]\\d+")              # "p1" -- letter + group number
str_match(x, "^([prc])(\\d+)_(\\d+)_")    # cols: whole, letter, group, item
str_replace_all(x, "\\s+", " ")           # collapse repeated spaces
```

## 6. Handy extras

- Case-insensitive: `str_detect(x, regex("pollin", ignore_case = TRUE))`
- Treat the pattern as plain text (no regex): `fixed("p1_3")`
- Lookahead, keep digits only if followed by `_`: `"\\d+(?=_)"`
- tidyselect helpers take regex too: `select(raw, matches("^p\\d+_"))`
  (`starts_with("p")` is *not* regex and also catches `permit1`)

## 7. When a pattern misbehaves

1. `str_view(x, p)` and look at what is highlighted.
2. Build up one piece at a time: `"^p"`, then `"^p\\d"`, then `"^p\\d+"`...
3. Syntax error? Check: forward vs back slashes, a quantifier with nothing before it, unbalanced `(` or `[`.
4. No match at all? Check you doubled the backslashes.
5. Matches too much? Add `^` / `$`, or tighten `.` to `\\d` or `[a-z]`.

More: `vignette("regular-expressions", package = "stringr")`
