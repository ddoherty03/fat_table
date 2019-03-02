
# Table of Contents

1.  [Introduction](#org23d768e)
2.  [Installation](#org8d90fdf)
    1.  [Prerequisites](#org26d2aee)
    2.  [Installing the gem](#orga19109b)
3.  [Usage](#org0b5ecd8)
    1.  [Quick Start](#org199fc3a)
    2.  [A Word About the Examples](#org1e51988)
    3.  [Anatomy of a Table](#org7d48b5d)
        1.  [Columns](#org4a6c98f)
        2.  [Headers](#org37bbf47)
        3.  [Groups](#org1c03cc1)
    4.  [Constructing Tables](#orgbf0e735)
        1.  [Empty Tables](#org80c41f5)
        2.  [From CSV or Org Mode files or strings](#org681a599)
        3.  [From Arrays of Arrays](#org4f683cf)
        4.  [From Arrays of Hashes](#org7980800)
        5.  [From SQL queries](#orgdab2ec1)
        6.  [Marking Groups in Input](#orgeb97e36)
    5.  [Accessing Parts of Tables](#orgf9cb237)
        1.  [Rows](#org4453cea)
        2.  [Columns](#org8a6dd85)
        3.  [Cells](#orgcc87a8b)
        4.  [Other table attributes](#org4a41de4)
    6.  [Operations on Tables](#org731fd13)
        1.  [Example Input Table](#orga96ca08)
        2.  [Select](#orga0c49b3)
        3.  [Where](#orge185ad7)
        4.  [Order\_by](#org57f51d1)
        5.  [Group\_by](#org1ee0a85)
        6.  [Join](#org6432f26)
        7.  [Set Operations](#org7d2857d)
        8.  [Uniq (aka Distinct)](#org073a8b5)
        9.  [Remove groups with degroup!](#orgd147303)
    7.  [Formatting Tables](#org9f4d633)
        1.  [Available Formatters](#orgb7b2335)
        2.  [Table Locations](#org4db9ae4)
        3.  [Formatting Directives](#orgd2128a3)
        4.  [Footers Methods](#org947e8a4)
        5.  [Formatting Methods](#orgcef241a)
        6.  [The `format` and `format_for` methods](#org7b25866)
4.  [Development](#org62e325b)
5.  [Contributing](#orgf51a2c9)

[![Build Status](https://travis-ci.org/ddoherty03/fat_table.svg?branch=v0.2.7)](https://travis-ci.org/ddoherty03/fat_table)

<a id="org23d768e"></a>

# Introduction

`FatTable` is a gem that treats tables as a data type. It provides methods for
constructing tables from a variety of sources, building them row-by-row,
extracting rows, columns, and cells, and performing aggregate operations on
columns. It also provides as set of SQL-esque methods for manipulating table
objects: `select` for filtering by columns or for creating new columns, `where`
for filtering by rows, `order_by` for sorting rows, `distinct` for eliminating
duplicate rows, `group_by` for aggregating multiple rows into single rows and
applying column aggregate methods to ungrouped columns, a collection of `join`
methods for combining tables, and more.

Furthermore, `FatTable` provides methods for formatting tables and producing
output that targets various output media: text, ANSI terminals, ruby data
structures, LaTeX tables, Emacs org-mode tables, and more. The formatting
methods can specify cell formatting in a way that is uniform across all the
output methods and can also decorate the output with any number of footers,
including group footers. `FatTable` applies formatting directives to the extent
they makes sense for the output medium and treats other formatting directives as
no-ops.

`FatTable` can be used to perform operations on data that are naturally best
conceived of as tables, which in my experience is quite often. It can also serve
as a foundation for providing reporting functions where flexibility about the
output medium can be quite useful. Finally `FatTable` can be used within Emacs
`org-mode` files in code blocks targeting the Ruby language. Org mode tables are
presented to a ruby code block as an array of arrays, so `FatTable` can read
them in with its `.from_aoa` constructor. A `FatTable` table output as an array
of arrays with its `.to_aoa` output function will be rendered in an org-mode
buffer as an org-table, ready for processing by other code blocks.


<a id="org8d90fdf"></a>

# Installation


<a id="org26d2aee"></a>

## Prerequisites

The `fat_table` gem depends on several libraries being available for building,
mostly those concerned with accessing databases.  On an ubuntu system, the
following packages should be installed before you install the `fat_table` gem:

-   ruby-dev
-   build-essential
-   libsqlite3-dev
-   libpq-dev
-   libmysqlclient-dev


<a id="orga19109b"></a>

## Installing the gem

Add this line to your application&rsquo;s Gemfile:

    gem 'fat_table'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fat_table


<a id="org0b5ecd8"></a>

# Usage


<a id="org199fc3a"></a>

## Quick Start

`FatTable` provides table objects as a data type that can be constructed and
operated on in a number of ways. Here&rsquo;s a quick example to illustrate the use of
the main features of `FatTable`. See the detailed explanations further on down.

    require 'fat_table'

    data =
        [['Date', 'Code', 'Raw', 'Shares', 'Price', 'Info', 'Ok'],
         ['2013-05-29', 'S', 15_700.00, 6601.85, 24.7790, 'ENTITY3', 'F'],
         ['2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500, 'ENTITY1', 'T'],
         ['2013-05-20', 'S', 12_000.00, 5046.00, 28.2804, 'ENTITY3', 'F'],
         ['2013-05-23', 'S', 8000.00, 3364.00, 27.1083, 'ENTITY3', 'T'],
         ['2013-05-23', 'S', 39_906.00, 16_780.47, 25.1749, 'ENTITY3', 'T'],
         ['2013-05-20', 'S', 85_000.00, 35_742.50, 28.3224, 'ENTITY3', 'T'],
         ['2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850, 'ENTITY1', 'T'],
         ['2013-05-29', 'S', 13_459.00, 5659.51, 24.7464, 'ENTITY3', 'T'],
         ['2013-05-20', 'S', 33_302.00, 14_003.49, 28.6383, 'ENTITY3', 'T'],
         ['2013-05-29', 'S', 15_900.00, 6685.95, 24.5802, 'ENTITY3', 'T'],
         ['2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ENTITY3', 'T'],
         ['2013-05-23', 'S', 23_054.00, 9694.21, 26.8015, 'ENTITY3', 'F']]

    # Build the Table and then perform chained operations on it

    table = FatTable.from_aoa(data) \
      .where('shares > 2000') \
      .order_by(:date, :code) \
      .select(:date, :code, :shares,
              :price, :ok, ref: '@row') \
      .select(:ref, :date, :code,
              :shares, :price, :ok)

    # Convert the table to an ASCII text string

    table.to_text do |fmt|
      # Add some table footers
      fmt.avg_footer(:price, :shares)
      fmt.sum_footer(:shares)
      # Add a group footer
      fmt.gfooter('Avg', shares: :avg, price: :avg)
      # Formats for all locations
      fmt.format(ref: 'CB', numeric: 'R', boolean: 'CY')
      # Formats for different "locations" in the table
      fmt.format_for(:header, string: 'CB')
      fmt.format_for(:body, code: 'C', shares: ',0.1', price: '0.4', )
      fmt.format_for(:bfirst, price: '$0.4', )
      fmt.format_for(:footer, shares: 'B,0.1', price: '$B0.4', )
      fmt.format_for(:gfooter, shares: 'B,0.1', price: 'B0.4', )
    end

    +=========+============+======+=============+==========+====+
    |   Ref   |    Date    | Code |    Shares   |   Price  | Ok |
    +---------|------------|------|-------------|----------|----+
    |    1    | 2013-05-02 |   P  |   118,186.4 | $11.8500 |  Y |
    |    2    | 2013-05-02 |   P  |   795,546.2 |   1.1850 |  Y |
    +---------|------------|------|-------------|----------|----+
    |   Avg   |            |      |   456,866.3 |   6.5175 |    |
    +---------|------------|------|-------------|----------|----+
    |    3    | 2013-05-20 |   S  |     5,046.0 |  28.2804 |  N |
    |    4    | 2013-05-20 |   S  |    35,742.5 |  28.3224 |  Y |
    |    5    | 2013-05-20 |   S  |    14,003.5 |  28.6383 |  Y |
    +---------|------------|------|-------------|----------|----+
    |   Avg   |            |      |    18,264.0 |  28.4137 |    |
    +---------|------------|------|-------------|----------|----+
    |    6    | 2013-05-23 |   S  |     3,364.0 |  27.1083 |  Y |
    |    7    | 2013-05-23 |   S  |    16,780.5 |  25.1749 |  Y |
    |    8    | 2013-05-23 |   S  |     9,694.2 |  26.8015 |  N |
    +---------|------------|------|-------------|----------|----+
    |   Avg   |            |      |     9,946.2 |  26.3616 |    |
    +---------|------------|------|-------------|----------|----+
    |    9    | 2013-05-29 |   S  |     6,601.9 |  24.7790 |  N |
    |    10   | 2013-05-29 |   S  |     5,659.5 |  24.7464 |  Y |
    |    11   | 2013-05-29 |   S  |     6,686.0 |  24.5802 |  Y |
    +---------|------------|------|-------------|----------|----+
    |   Avg   |            |      |     6,315.8 |  24.7019 |    |
    +---------|------------|------|-------------|----------|----+
    |    12   | 2013-05-30 |   S  |     2,808.5 |  25.0471 |  Y |
    +---------|------------|------|-------------|----------|----+
    |   Avg   |            |      |     2,808.5 |  25.0471 |    |
    +---------|------------|------|-------------|----------|----+
    | Average |            |      |    85,009.9 | $23.0428 |    |
    +---------|------------|------|-------------|----------|----+
    |  Total  |            |      | 1,020,119.1 |          |    |
    +=========+============+======+=============+==========+====+


<a id="org1e51988"></a>

## A Word About the Examples

When you install the `fat_table` gem, you have access to a program `ft_console`
which opens a `pry` session with `fat_table` loaded and the tables used in the
examples in this `README` defined as instance variables so you can experiment
with them. Because they are defined as instance variables, you have to write
`tab1` as `@tab1` in `ft_console`, but otherwise the examples should work.

The examples in this `README` file are executed as code blocks within the
`README.org` file, so they typically end with a call to `.to_aoa`. That causes
the table to be inserted into the file and formatted as a table. With
`ft_console`, you should instead display your tables with `.to_text` or
`.to_term`. These will return a string that you can print to the terminal with
`puts`.

To read in the table used in the Quick Start section above, you might do the
following:

    $ ft_console[1] pry(main)> ls
    ActiveSupport::ToJsonWithActiveSupportEncoder#methods: to_json
    self.methods: inspect  to_s
    instance variables:
      @aoa   @tab1      @tab2      @tab_a      @tab_b      @tt
      @data  @tab1_str  @tab2_str  @tab_a_str  @tab_b_str
    locals: _  __  _dir_  _ex_  _file_  _in_  _out_  _pry_  lib  str  version
    [2] pry(main)> table = FatTable.from_aoa(@data)
    => #<FatTable::Table:0x0055b40e6cd870
     @boundaries=[],
     @columns=
      [#<FatTable::Column:0x0055b40e6cc948
        @header=:date,
        @items=
         [Wed, 29 May 2013,
          Thu, 02 May 2013,
          Mon, 20 May 2013,
          Thu, 23 May 2013,
          Thu, 23 May 2013,
          Mon, 20 May 2013,
          Thu, 02 May 2013,
          Wed, 29 May 2013,
          Mon, 20 May 2013,
    ...
        @items=["ENTITY3", "ENTITY1", "ENTITY3", "ENTITY3", "ENTITY3", "ENTITY3", "ENTITY1", "ENTITY3", "ENTITY3", "ENTITY3", "ENTITY3", "ENTITY3"],
        @raw_header=:info,
        @type="String">,
       #<FatTable::Column:0x0055b40e6d2668 @header=:ok, @items=[false, true, false, true, true, true, true, true, true, true, true, false], @raw_header=:ok, @type="Boolean">]>
    [3] pry(main)> puts table.to_text
    +============+======+==========+==========+=========+=========+====+
    | Date       | Code | Raw      | Shares   | Price   | Info    | Ok |
    +------------|------|----------|----------|---------|---------|----+
    | 2013-05-29 | S    | 15700.0  | 6601.85  | 24.779  | ENTITY3 | F  |
    | 2013-05-02 | P    | 118186.4 | 118186.4 | 11.85   | ENTITY1 | T  |
    | 2013-05-20 | S    | 12000.0  | 5046.0   | 28.2804 | ENTITY3 | F  |
    | 2013-05-23 | S    | 8000.0   | 3364.0   | 27.1083 | ENTITY3 | T  |
    | 2013-05-23 | S    | 39906.0  | 16780.47 | 25.1749 | ENTITY3 | T  |
    | 2013-05-20 | S    | 85000.0  | 35742.5  | 28.3224 | ENTITY3 | T  |
    | 2013-05-02 | P    | 795546.2 | 795546.2 | 1.185   | ENTITY1 | T  |
    | 2013-05-29 | S    | 13459.0  | 5659.51  | 24.7464 | ENTITY3 | T  |
    | 2013-05-20 | S    | 33302.0  | 14003.49 | 28.6383 | ENTITY3 | T  |
    | 2013-05-29 | S    | 15900.0  | 6685.95  | 24.5802 | ENTITY3 | T  |
    | 2013-05-30 | S    | 6679.0   | 2808.52  | 25.0471 | ENTITY3 | T  |
    | 2013-05-23 | S    | 23054.0  | 9694.21  | 26.8015 | ENTITY3 | F  |
    +============+======+==========+==========+=========+=========+====+
    => nil
    [4] pry(main)>

And if you use `.to_term`, you can see the effect of the color formatting
directives.


<a id="org7d48b5d"></a>

## Anatomy of a Table


<a id="org4a6c98f"></a>

### Columns

`FatTable::Table` objects consist of an array of `FatTable::Column` objects.
Each `Column` has a header, a type, and an array of items, all of the given type
or nil. There are only five permissible types for a `Column`:

1.  **Boolean** (for holding ruby `TrueClass` and `FalseClass` objects),
2.  **DateTime** (for holding ruby `DateTime` or `Date` objects),
3.  **Numeric** (for holding ruby `Integer`, `Rational`, or `BigDecimal` objects),
4.  **String** (for ruby `String` objects), or
5.  **NilClass** (for the undetermined column type).

When a `Table` is constructed from an external source, all `Columns` start out
having a type of `NilClass`, that is, their type is as yet undetermined. When a
string or object of one of the four determined types is added to a `Column`, it
fixes the type of the column and all further items added to the `Column` must
either be `nil` (indicating no value) or be capable of being coerced to the
column&rsquo;s type. Otherwise, `FatTable` raises an exception.

Items of input must be either one of the permissible ruby objects or strings. If
they are strings, `FatTable` attempts to parse them as one of the permissible
types as follows:

-   **Boolean:** the strings, `'t'`, `'true'`, `'yes'`, or `'y'`, regardless of
    case, are interpreted as `TrueClass` and the strings, `'f'`, `'false'`,
    `'no'`, or `'n'`, regardless of case, are interpreted as `FalseClass`, in
    either case resulting in a Boolean column. Empty strings in a column
    already having a Boolean type are converted to `nil`.
-   **DateTime:** strings that contain patterns of `'yyyy-mm-dd'` or `'yyyy/mm/dd'`
    or `'mm-dd-yyy'` or `'mm/dd/yyyy'` or any of the foregoing with an added
    `'Thh:mm:ss'` or `'Thh:mm'` will be interpreted as a `DateTime` or a `Date`
    (if there are no sub-day time components present). The number of digits in
    the month and day can be one or two, but the year component must be four
    digits. Any time components are valid if they can be properly interpreted
    by `DateTime.parse`. Org mode timestamps (any of the foregoing surrounded
    by square &rsquo;`[]`&rsquo; or pointy &rsquo;`<>`&rsquo; brackets), active or inactive, are valid
    input strings for `DateTime` columns. Empty strings in a column already
    having the `DateTime` type are converted to `nil`.
-   **Numeric:** all commas `','`, underscores, `'_'`, and `'$'` dollar signs (or
    other currency symbol as set by `FatTable.currency_symbol` are removed from
    the string and if the remaining string can be interpreted as a `Numeric`,
    it will be. It is interpreted as an `Integer` if there are no decimal
    places in the remaining string, as a `Rational` if the string has the form
    &rsquo;`<number>:<number>`&rsquo; or &rsquo;`<number>/<number>`&rsquo;, or as a `BigDecimal` if
    there is a decimal point in the remaining string. Empty strings in a column
    already having the Numeric type are converted to nil.
-   **String:** if all else fails, `FatTable` applies `#to_s` to the input value
    and, treats it as an item of type `String`. Empty strings in a column
    already having the `String` type are kept as empty strings.
-   **NilClass:** until the input contains a non-blank string that can be parsed as
    one of the other types, it has this type, meaning that the type is still
    open. A column comprised completely of blank strings or `nils` will retain
    the `NilClass` type.


<a id="org37bbf47"></a>

### Headers

Headers for the columns are formed from the input. No two columns in a table can
have the same header. Headers in the input are converted to symbols by

-   converting the header to a string with `#to_s`,
-   converting any run of blanks to an underscore `_`,
-   removing any characters that are not letters, numbers, or underscores, and
-   lowercasing all remaining letters

Thus, a header of `'Date'` becomes `:date`, a header of `'Id Number'` becomes,
`:id_number`, etc. When referring to a column in code, you must use the symbol
form of the header.

If no sensible headers can be discerned from the input, headers of the form
`:col_1`, `:col_2`, etc., are synthesized.


<a id="org1c03cc1"></a>

### Groups

The rows of a `FatTable` table can be sub-divided into groups, either from
markers in the input or as a result of certain operations. There is only one
level of grouping, so `FatTable` has no concept of sub-groups. Groups can be
shown on output with rules or &ldquo;hlines&rdquo; that underline the last row in each
group, and you can decorate the output with group footers that summarize the
columns in each group.


<a id="orgbf0e735"></a>

## Constructing Tables


<a id="org80c41f5"></a>

### Empty Tables

You can create an empty table with `FatTable.new`, and then add rows with the
`<<` operator and a Hash:

    tab = FatTable.new
    tab << { a: 1, b: 2, c: "<2017-01-21>', d: 'f', e: '' }
    tab << { a: 3.14, b: 2.17, c: '[2016-01-21 Thu]', d: 'Y', e: nil }
    tab.to_aoa

After this, the table will have column headers `:a`, `:b`, `:c`, `:d`, and `:e`.
Column, `:a` and `:b` will have type Numeric, column `:c` will have type
`DateTime`, and column `:d` will have type `Boolean`. Column `:e` will still
have an open type. Notice that dates in the input can be wrapped in brackets as
in org-mode time stamps.


<a id="org681a599"></a>

### From CSV or Org Mode files or strings

Tables can also be read from `.csv` files or files containing `org-mode` tables.
In the case of org-mode files, `FatTable` skips through the file until it finds
a line that look like a table, that is, it begins with any number of spaces
followed by `|-`. Only the first table in an `.org` file is read.

For both `.csv` and `.org` files, the first row in the tables is taken as the
header row, and the headers are converted to symbols as described above.

        tab1 = FatTable.from_csv_file('~/data.csv')
        tab2 = FatTable.from_org_file('~/project.org')

        csv_body = <<-EOS
      Ref,Date,Code,RawShares,Shares,Price,Info
      1,2006-05-02,P,5000,5000,8.6000,2006-08-09-1-I
      2,2006-05-03,P,5000,5000,8.4200,2006-08-09-1-I
      3,2006-05-04,P,5000,5000,8.4000,2006-08-09-1-I
      4,2006-05-10,P,8600,8600,8.0200,2006-08-09-1-D
      5,2006-05-12,P,10000,10000,7.2500,2006-08-09-1-D
      6,2006-05-12,P,2000,2000,6.7400,2006-08-09-1-I
      EOS

        tab3 = FatTable.from_csv_string(csv_body)

        org_body = <<-EOS
    .* Smith Transactions
    :PROPERTIES:
    :TABLE_EXPORT_FILE: smith.csv
    :END:

    #+TBLNAME: smith_tab
    | Ref |       Date | Code |     Raw | Shares |    Price | Info    |
    |-----|------------|------|---------|--------|----------|---------|
    |  29 | 2013-05-02 | P    | 795,546 |  2,609 |  1.18500 | ENTITY1 |
    |  30 | 2013-05-02 | P    | 118,186 |    388 | 11.85000 | ENTITY1 |
    |  31 | 2013-05-02 | P    | 340,948 |  1,926 |  1.18500 | ENTITY2 |
    |  32 | 2013-05-02 | P    |  50,651 |    286 | 11.85000 | ENTITY2 |
    |  33 | 2013-05-20 | S    |  12,000 |     32 | 28.28040 | ENTITY3 |
    |  34 | 2013-05-20 | S    |  85,000 |    226 | 28.32240 | ENTITY3 |
    |  35 | 2013-05-20 | S    |  33,302 |     88 | 28.63830 | ENTITY3 |
    |  36 | 2013-05-23 | S    |   8,000 |     21 | 27.10830 | ENTITY3 |
    |  37 | 2013-05-23 | S    |  23,054 |     61 | 26.80150 | ENTITY3 |
    |  38 | 2013-05-23 | S    |  39,906 |    106 | 25.17490 | ENTITY3 |
    |  39 | 2013-05-29 | S    |  13,459 |     36 | 24.74640 | ENTITY3 |
    |  40 | 2013-05-29 | S    |  15,700 |     42 | 24.77900 | ENTITY3 |
    |  41 | 2013-05-29 | S    |  15,900 |     42 | 24.58020 | ENTITY3 |
    |  42 | 2013-05-30 | S    |   6,679 |     18 | 25.04710 | ENTITY3 |

    .* Another Heading
    EOS

        tab4 = FatTable.from_org_string(org_body)


<a id="org4f683cf"></a>

### From Arrays of Arrays

You can also initialize a table directly from ruby data structures. You can, for
example, build a table from an array of arrays:

    aoa = [
      ['Ref', 'Date', 'Code', 'Raw', 'Shares', 'Price', 'Info', 'Bool'],
      [1, '2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850, 'ENTITY1', 'T'],
      [2, '2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500, 'ENTITY1', 'T'],
      [7, '2013-05-20', 'S', 12_000.00, 5046.00, 28.2804, 'ENTITY3', 'F'],
      [8, '2013-05-20', 'S', 85_000.00, 35_742.50, 28.3224, 'ENTITY3', 'T'],
      [9, '2013-05-20', 'S', 33_302.00, 14_003.49, 28.6383, 'ENTITY3', 'T'],
      [10, '2013-05-23', 'S', 8000.00, 3364.00, 27.1083, 'ENTITY3', 'T'],
      [11, '2013-05-23', 'S', 23_054.00, 9694.21, 26.8015, 'ENTITY3', 'F'],
      [12, '2013-05-23', 'S', 39_906.00, 16_780.47, 25.1749, 'ENTITY3', 'T'],
      [13, '2013-05-29', 'S', 13_459.00, 5659.51, 24.7464, 'ENTITY3', 'T'],
      [14, '2013-05-29', 'S', 15_700.00, 6601.85, 24.7790, 'ENTITY3', 'F'],
      [15, '2013-05-29', 'S', 15_900.00, 6685.95, 24.5802, 'ENTITY3', 'T'],
      [16, '2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ENTITY3', 'T']
    ]
    tab = FatTable.from_aoa(aoa)

Notice that the values can either be ruby objects, such as the Integer `85_000`,
or strings that can be parsed into one of the permissible column types.

This method of building a table, `.from_aoa`, is particularly useful in dealing
with Emacs org-mode code blocks. Tables in org-mode are passed to code blocks as
arrays of arrays. Likewise, a result of a code block in the form of an array of
arrays is displayed as an org-mode table:

    #+NAME: trades1
    | Ref  |       Date | Code |  Price | G10 | QP10 | Shares |    LP |     QP |   IPLP |   IPQP |
    |------|------------|------|--------|-----|------|--------|-------|--------|--------|--------|
    | T001 | 2016-11-01 | P    | 7.7000 | T   | F    |    100 |    14 |     86 | 0.2453 | 0.1924 |
    | T002 | 2016-11-01 | P    | 7.7500 | T   | F    |    200 |    28 |    172 | 0.2453 | 0.1924 |
    | T003 | 2016-11-01 | P    | 7.5000 | F   | T    |    800 |   112 |    688 | 0.2453 | 0.1924 |
    | T004 | 2016-11-01 | S    | 7.5500 | T   | F    |   6811 |   966 |   5845 | 0.2453 | 0.1924 |
    | T005 | 2016-11-01 | S    | 7.5000 | F   | F    |   4000 |   572 |   3428 | 0.2453 | 0.1924 |
    | T006 | 2016-11-01 | S    | 7.6000 | F   | T    |   1000 |   143 |    857 | 0.2453 | 0.1924 |
    | T007 | 2016-11-01 | S    | 7.6500 | T   | F    |    200 |    28 |    172 | 0.2453 | 0.1924 |
    | T008 | 2016-11-01 | P    | 7.6500 | F   | F    |   2771 |   393 |   2378 | 0.2453 | 0.1924 |
    | T009 | 2016-11-01 | P    | 7.6000 | F   | F    |   9550 |  1363 |   8187 | 0.2453 | 0.1924 |
    | T010 | 2016-11-01 | P    | 7.5500 | F   | T    |   3175 |   451 |   2724 | 0.2453 | 0.1924 |
    | T011 | 2016-11-02 | P    | 7.4250 | T   | F    |    100 |    14 |     86 | 0.2453 | 0.1924 |
    | T012 | 2016-11-02 | P    | 7.5500 | F   | F    |   4700 |   677 |   4023 | 0.2453 | 0.1924 |
    | T013 | 2016-11-02 | P    | 7.3500 | T   | T    |  53100 |  7656 |  45444 | 0.2453 | 0.1924 |
    | T014 | 2016-11-02 | P    | 7.4500 | F   | T    |   5847 |   835 |   5012 | 0.2453 | 0.1924 |
    | T015 | 2016-11-02 | P    | 7.7500 | F   | F    |    500 |    72 |    428 | 0.2453 | 0.1924 |
    | T016 | 2016-11-02 | P    | 8.2500 | T   | T    |    100 |    14 |     86 | 0.2453 | 0.1924 |

    #+HEADER: :colnames no
    :#+BEGIN_SRC ruby :var tab=trades1
      require 'fat_table'
      tab = FatTable.from_aoa(tab).where('shares > 500')
      tab.to_aoa
    :#+END_SRC

    #+RESULTS:
    | Ref  |       Date | Code | Price | G10 | QP10 | Shares |   Lp |    Qp |   Iplp |   Ipqp |
    |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
    | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
    | T004 | 2016-11-01 | S    |  7.55 | T   | F    |   6811 |  966 |  5845 | 0.2453 | 0.1924 |
    | T005 | 2016-11-01 | S    |   7.5 | F   | F    |   4000 |  572 |  3428 | 0.2453 | 0.1924 |
    | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
    | T008 | 2016-11-01 | P    |  7.65 | F   | F    |   2771 |  393 |  2378 | 0.2453 | 0.1924 |
    | T009 | 2016-11-01 | P    |   7.6 | F   | F    |   9550 | 1363 |  8187 | 0.2453 | 0.1924 |
    | T010 | 2016-11-01 | P    |  7.55 | F   | T    |   3175 |  451 |  2724 | 0.2453 | 0.1924 |
    | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
    | T013 | 2016-11-02 | P    |  7.35 | T   | T    |  53100 | 7656 | 45444 | 0.2453 | 0.1924 |
    | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 |  835 |  5012 | 0.2453 | 0.1924 |

This example illustrates several things:

1.  The named org-mode table, `trades1`, can be passed into a ruby code block
    using the `:var tab=trades1` header argument to the code block; that makes
    the variable `tab` available to the code block as an array of arrays, which
    `FatTable` then uses to initialize the table.
2.  The code block requires that you set `:colnames no` in the header arguments.
    This suppresses org-mode&rsquo;s own processing of the header line so that
    `FatTable` can see the headers. Failure to do this will cause an error.
3.  The table is subjected to some processing, in this case selecting those rows
    where the number of shares is greater than 500.  More on that later.
4.  `FatTable` passes back to org-mode an array of arrays using the `.to_aoa`
    method. In an `org-mode` buffer, these are rendered as tables. We&rsquo;ll often
    apply `.to_aoa` at the end of example blocks to render the results inside
    this `README.org` file. As we&rsquo;ll see below, this method can also take a block
    to which formatting directives and footers can be attached.


<a id="org7980800"></a>

### From Arrays of Hashes

A second ruby data structure that can be used to initialize a `FatTable` table
is an array of ruby Hashes. Each hash represents a row of the table, and the
headers of the table are take from the keys of the hashes. Accordingly, all the
hashes should have the same keys.

This same method can in fact take an array of any objects that can be converted
to a Hash with the `#to_h` method, so you can use an array of your own objects
to initialize a table, provided that you define a suitable `#to_h` method for
the objects&rsquo; class.

    aoh = [
      { ref: 'T001', date: '2016-11-01', code: 'P', price: '7.7000',  shares: 100 },
      { ref: 'T002', date: '2016-11-01', code: 'P', price: 7.7500,  shares: 200 },
      { ref: 'T003', date: '2016-11-01', code: 'P', price: 7.5000,  shares: 800 },
      { ref: 'T004', date: '2016-11-01', code: 'S', price: 7.5500,  shares: 6811 },
      { ref: 'T005', date: Date.today, code: 'S', price: 7.5000,  shares: 4000 },
      { ref: 'T006', date: '2016-11-01', code: 'S', price: 7.6000,  shares: 1000 },
      { ref: 'T007', date: '2016-11-01', code: 'S', price: 7.6500,  shares: 200 },
      { ref: 'T008', date: '2016-11-01', code: 'P', price: 7.6500,  shares: 2771 },
      { ref: 'T009', date: '2016-11-01', code: 'P', price: 7.6000,  shares: 9550 },
      { ref: 'T010', date: '2016-11-01', code: 'P', price: 7.5500,  shares: 3175 },
      { ref: 'T011', date: '2016-11-02', code: 'P', price: 7.4250,  shares: 100 },
      { ref: 'T012', date: '2016-11-02', code: 'P', price: 7.5500,  shares: 4700 },
      { ref: 'T013', date: '2016-11-02', code: 'P', price: 7.3500,  shares: 53100 },
      { ref: 'T014', date: '2016-11-02', code: 'P', price: 7.4500,  shares: 5847 },
      { ref: 'T015', date: '2016-11-02', code: 'P', price: 7.7500,  shares: 500 },
      { ref: 'T016', date: '2016-11-02', code: 'P', price: 8.2500,  shares: 100 }
    ]
    tab = FatTable.from_aoh(aoh)

Notice, again, that the values can either be ruby objects, such as `Date.today`,
or strings that can parsed into one of the permissible column types.


<a id="orgdab2ec1"></a>

### From SQL queries

Another way to initialize a `FatTable` table is with the results of a SQL query.
`FatTable` uses the `sequel` gem to query databases. You must first set the
database parameters to be used for the queries.

    # This automatically requires sequel.
    require 'fat_table'
    FatTable.connect(driver: 'Pg',
                    database: 'XXX_development',
                    user: 'dtd',
                    password: 'slflpowert',
                    host: 'localhost',
                    socket: '/tmp/.s.PGSQL.5432')
    tab = FatTable.from_sql('select * from trades;')

Some of the parameters to the `.connect` function have defaults. The driver
defaults to `'Pg'` for postgresql and the socket defaults to
`/tmp/.s.PGSQL.5432` if the host is &rsquo;localhost&rsquo;, which it is by default. If the
host is not `'localhost'`, the dsn uses a port rather than a socket and defaults
to port `'5432'`. While user and password default to nil, the database parameter
is required.

The `.connect` function need only be called once, and the database handle it
creates will be used for all subsequent `.from_sql` calls until `.connect` is
called again.

Alternatively, you can build the `Sequel` connection with `Sequel.connect` or
with adapter-specific `Sequel` connection methods and let `FatTable` know to use
that connection:

    require 'fat_table'
    FatTable.db = Sequel.connect('postgres://user:password@localhost/dbname')
    FatTable.db = Sequel.ado(conn_string: 'Provider=Microsoft.ACE.OLEDB.12.0;Data Source=drive:\path\filename.accdb')

Consult `Sequel's` documentation for details on its connection methods.
<http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html>


<a id="orgeb97e36"></a>

### Marking Groups in Input

The `.from_aoa` and `.from_aoh` functions take an optional keyword parameter
`hlines:` that, if set to `true`, causes them to mark group boundaries in the
table wherever a row Array (for `.from_aoa`) or Hash (for `.from_aoh`) is
followed by a `nil`. Each boundary means that the rows above it and after the
header or prior group boundary all belong to a group. By default `hlines` is
false for both functions so neither expects hlines in its input.

In the case of `.from_aoa`, if `hlines:` is set true, the input must also
include a `nil` in the second element of the outer array to indicate that the
first row is to be used as headers.  Otherwise, it will synthesize headers of
the form `:col_1`, `:col_2`, &#x2026; `:col_n`.

In org mode table text passed to `.from_org_file` and `.from_org_string`, you
*must* mark the header row by following it with an hrule and you *may* mark
group boundaries with an hrule. In org mode tables, hlines are table rows
beginning with something like &rsquo;`|---`&rsquo;. The `.from_org_...` functions always
recognizes hlines in the input, so it takes no `hlines:` keyword parameter.


<a id="orgf9cb237"></a>

## Accessing Parts of Tables


<a id="org4453cea"></a>

### Rows

A `FatTable` table is an Enumerable, yielding each row of the table as a Hash
keyed on the header symbols. The method `Table#rows` returns an Array of the
rows as Hashes as well.

You can also use indexing to access a row of the table by number. Using an
integer index returns a Hash of the given row. Thus, `tab[20]` returns the 21st
data row of the table, while `tab[0]` returns the first row and tab[-1] returns
the last row.


<a id="org8a6dd85"></a>

### Columns

If the index provided to `[]` is a string or a symbol, it returns an Array of
the items of the column with that header. Thus, `tab[:ref]` returns an Array of
all the items of the table&rsquo;s `:ref` column.


<a id="orgcc87a8b"></a>

### Cells

The two forms of indexing can be combined to access individual cells of the
table:

    tab[13]         # => Hash of the 14th row
    tab[:date]      # => Array of all Dates in the :date column
    tab[13][:date]  # => The Date in the 14th row
    tab[:date][13]  # => The Date in the 14th row; indexes can be in either order.


<a id="org4a41de4"></a>

### Other table attributes

    tab.headers       # => an Array of the headers in symbol form
    tab.types         # => a Hash mapping headers to column types
    tab.size          # => the number of rows in the table
    tab.width         # => the number of columns in the table
    tab.empty?        # => is the table empty?
    tab.column?(head) # => does the table have a column with the given header?
    tab.groups        # => return an Array of the table's groups as Arrays of row Hashes.


<a id="org731fd13"></a>

## Operations on Tables

Once you have one or more tables, you will likely want to perform operations on
them. The operations provided by `FatTable` are the subject of this section.
Before getting into the operations, though, there are a couple of issues that
cut across all or many of the operations.

First, tables are by and large immutable objects. Each operation creates a new
table without affecting the input tables. The only exception is the `degroup!`
operation, which mutates the receiver table by removing its group boundaries.

Second, because each operation returns a `FatTable::Table` object, the
operations are chainable.

Third, `FatTable::Table` objects can have &ldquo;groups&rdquo; of rows within the table.
These can be decorated with hlines and group footers on output. Some of these
operations result in marking group boundaries in the result table, others remove
group boundaries that may have existed in the input table. Operations that
either create or remove groups will be noted below.

Finally, the operations are for the most part patterned on SQL table operations,
but when expressions play a role, you write them using ruby syntax rather than
SQL.


<a id="orga96ca08"></a>

### Example Input Table

For illustration purposes assume that the following tables are read into ruby
variables called &rsquo;`tab1`&rsquo; and &rsquo;`tab2`. We have given the table groups, marked by
the hlines below, and included some duplicate rows to illustrate the effect of
certain operations on groups and duplicates.

    require 'fat_table'

    tab1_str = <<-EOS
    | Ref  | Date             | Code |  Price | G10 | QP10 | Shares |   LP |    QP |   IPLP |   IPQP |
    |------|------------------|------|--------|-----|------|--------|------|-------|--------|--------|
    | T001 | [2016-11-01 Tue] | P    | 7.7000 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    | T002 | [2016-11-01 Tue] | P    | 7.7500 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
    | T003 | [2016-11-01 Tue] | P    | 7.5000 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
    | T003 | [2016-11-01 Tue] | P    | 7.5000 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
    |------|------------------|------|--------|-----|------|--------|------|-------|--------|--------|
    | T004 | [2016-11-01 Tue] | S    | 7.5500 | T   | F    |   6811 |  966 |  5845 | 0.2453 | 0.1924 |
    | T005 | [2016-11-01 Tue] | S    | 7.5000 | F   | F    |   4000 |  572 |  3428 | 0.2453 | 0.1924 |
    | T006 | [2016-11-01 Tue] | S    | 7.6000 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
    | T006 | [2016-11-01 Tue] | S    | 7.6000 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
    | T007 | [2016-11-01 Tue] | S    | 7.6500 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
    | T008 | [2016-11-01 Tue] | P    | 7.6500 | F   | F    |   2771 |  393 |  2378 | 0.2453 | 0.1924 |
    | T009 | [2016-11-01 Tue] | P    | 7.6000 | F   | F    |   9550 | 1363 |  8187 | 0.2453 | 0.1924 |
    |------|------------------|------|--------|-----|------|--------|------|-------|--------|--------|
    | T010 | [2016-11-01 Tue] | P    | 7.5500 | F   | T    |   3175 |  451 |  2724 | 0.2453 | 0.1924 |
    | T011 | [2016-11-02 Wed] | P    | 7.4250 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    | T012 | [2016-11-02 Wed] | P    | 7.5500 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
    | T012 | [2016-11-02 Wed] | P    | 7.5500 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
    | T013 | [2016-11-02 Wed] | P    | 7.3500 | T   | T    |  53100 | 7656 | 45444 | 0.2453 | 0.1924 |
    |------|------------------|------|--------|-----|------|--------|------|-------|--------|--------|
    | T014 | [2016-11-02 Wed] | P    | 7.4500 | F   | T    |   5847 |  835 |  5012 | 0.2453 | 0.1924 |
    | T015 | [2016-11-02 Wed] | P    | 7.7500 | F   | F    |    500 |   72 |   428 | 0.2453 | 0.1924 |
    | T016 | [2016-11-02 Wed] | P    | 8.2500 | T   | T    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    EOS

    tab2_str = <<-EOS
    | Ref  | Date             | Code |  Price | G10 | QP10 | Shares |    LP |   QP |   IPLP |   IPQP |
    |------|------------------|------|--------|-----|------|--------|-------|------|--------|--------|
    | T003 | [2016-11-01 Tue] | P    | 7.5000 | F   | T    |    800 |   112 |  688 | 0.2453 | 0.1924 |
    | T003 | [2016-11-01 Tue] | P    | 7.5000 | F   | T    |    800 |   112 |  688 | 0.2453 | 0.1924 |
    | T017 | [2016-11-01 Tue] | P    |    8.3 | F   | T    |   1801 |  1201 |  600 | 0.2453 | 0.1924 |
    |------|------------------|------|--------|-----|------|--------|-------|------|--------|--------|
    | T018 | [2016-11-01 Tue] | S    |  7.152 | T   | F    |   2516 |  2400 |  116 | 0.2453 | 0.1924 |
    | T018 | [2016-11-01 Tue] | S    |  7.152 | T   | F    |   2516 |  2400 |  116 | 0.2453 | 0.1924 |
    | T006 | [2016-11-01 Tue] | S    | 7.6000 | F   | T    |   1000 |   143 |  857 | 0.2453 | 0.1924 |
    | T007 | [2016-11-01 Tue] | S    | 7.6500 | T   | F    |    200 |    28 |  172 | 0.2453 | 0.1924 |
    |------|------------------|------|--------|-----|------|--------|-------|------|--------|--------|
    | T014 | [2016-11-02 Wed] | P    | 7.4500 | F   | T    |   5847 |   835 | 5012 | 0.2453 | 0.1924 |
    | T015 | [2016-11-02 Wed] | P    | 7.7500 | F   | F    |    500 |    72 |  428 | 0.2453 | 0.1924 |
    | T015 | [2016-11-02 Wed] | P    | 7.7500 | F   | F    |    500 |    72 |  428 | 0.2453 | 0.1924 |
    | T016 | [2016-11-02 Wed] | P    | 8.2500 | T   | T    |    100 |    14 |   86 | 0.2453 | 0.1924 |
    |------|------------------|------|--------|-----|------|--------|-------|------|--------|--------|
    | T019 | [2017-01-15 Sun] | S    |   8.75 | T   | F    |    300 |   175 |  125 | 0.2453 | 0.1924 |
    | T020 | [2017-01-19 Thu] | S    |   8.25 | F   | T    |    700 |   615 |   85 | 0.2453 | 0.1924 |
    | T021 | [2017-01-23 Mon] | P    |   7.16 | T   | T    |  12100 | 11050 | 1050 | 0.2453 | 0.1924 |
    | T021 | [2017-01-23 Mon] | P    |   7.16 | T   | T    |  12100 | 11050 | 1050 | 0.2453 | 0.1924 |
    EOS

    tab1 = FatTable.from_org_string(tab1_str)
    tab2 = FatTable.from_org_string(tab2_str)


<a id="orga0c49b3"></a>

### Select

With the `select` method, you can select which existing columns should appear in
the output table and create new columns in the output table that are a function
of existing and new columns.

1.  Selecting Existing Columns

    Here we select three existing columns by simply passing header symbols in the
    order we want them to appear in the output. Thus, one use of `select` is to
    filter and permute the order of existing columns. The `select` method preserves
    any group boundaries present in the input table.

        tab1.select(:price, :ref, :shares).to_aoa

        | Price | Ref  | Shares |
        |-------|------|--------|
        |   7.7 | T001 |    100 |
        |  7.75 | T002 |    200 |
        |   7.5 | T003 |    800 |
        |   7.5 | T003 |    800 |
        |-------|------|--------|
        |  7.55 | T004 |   6811 |
        |   7.5 | T005 |   4000 |
        |   7.6 | T006 |   1000 |
        |   7.6 | T006 |   1000 |
        |  7.65 | T007 |    200 |
        |  7.65 | T008 |   2771 |
        |   7.6 | T009 |   9550 |
        |-------|------|--------|
        |  7.55 | T010 |   3175 |
        | 7.425 | T011 |    100 |
        |  7.55 | T012 |   4700 |
        |  7.55 | T012 |   4700 |
        |  7.35 | T013 |  53100 |
        |-------|------|--------|
        |  7.45 | T014 |   5847 |
        |  7.75 | T015 |    500 |
        |  8.25 | T016 |    100 |

2.  Adding New Columns

    More interesting is that `select` can take hash-like keyword arguments after the
    symbol arguments to create new columns in the output as functions of other
    columns. For each hash-like parameter, the keyword given must be a symbol, which
    becomes the header for the new column, and the value must be either: (1) a
    symbol representing an existing column, which has the effect of renaming an
    existing column, or (2) a string representing a ruby expression for the value of
    a new column.

    Within the string expression, the names of existing or already-specified columns
    are available as local variables, as well as the instance variables &rsquo;@row&rsquo; and
    &rsquo;@group&rsquo;. So for our example table, the string expressions for new columns have
    access to local variables `ref`, `date`, `code`, `price`, `g10`, `qp10`,
    `shares`, `lp`, `qp`, `iplp`, and `ipqp` as well as the instance variables
    `@row` and `@group`. The local variables are set to the values of the cell in
    their respective columns for each row in the input table and the instance
    variables are set the number of the current row and group respectively.

    For example, if we want to rename the `:date` column and add a new column to
    compute the cost of shares, we could do the following:

        tab1.select(:ref, :price, :shares, traded_on: :date, cost: 'price * shares').to_aoa

        | Ref  | Price | Shares |  Traded On |     Cost |
        |------|-------|--------|------------|----------|
        | T001 |   7.7 |    100 | 2016-11-01 |    770.0 |
        | T002 |  7.75 |    200 | 2016-11-01 |   1550.0 |
        | T003 |   7.5 |    800 | 2016-11-01 |   6000.0 |
        | T003 |   7.5 |    800 | 2016-11-01 |   6000.0 |
        |------|-------|--------|------------|----------|
        | T004 |  7.55 |   6811 | 2016-11-01 | 51423.05 |
        | T005 |   7.5 |   4000 | 2016-11-01 |  30000.0 |
        | T006 |   7.6 |   1000 | 2016-11-01 |   7600.0 |
        | T006 |   7.6 |   1000 | 2016-11-01 |   7600.0 |
        | T007 |  7.65 |    200 | 2016-11-01 |   1530.0 |
        | T008 |  7.65 |   2771 | 2016-11-01 | 21198.15 |
        | T009 |   7.6 |   9550 | 2016-11-01 |  72580.0 |
        |------|-------|--------|------------|----------|
        | T010 |  7.55 |   3175 | 2016-11-01 | 23971.25 |
        | T011 | 7.425 |    100 | 2016-11-02 |    742.5 |
        | T012 |  7.55 |   4700 | 2016-11-02 |  35485.0 |
        | T012 |  7.55 |   4700 | 2016-11-02 |  35485.0 |
        | T013 |  7.35 |  53100 | 2016-11-02 | 390285.0 |
        |------|-------|--------|------------|----------|
        | T014 |  7.45 |   5847 | 2016-11-02 | 43560.15 |
        | T015 |  7.75 |    500 | 2016-11-02 |   3875.0 |
        | T016 |  8.25 |    100 | 2016-11-02 |    825.0 |

    The parameter &rsquo;`traded_on: :date`&rsquo; caused the `:date` column of the input table
    to be renamed &rsquo;`:traded_on`, and the parameter `cost: 'price * shares'` created
    a new column, `:cost`, as the product of values in the `:price` and `:shares`
    columns.

    The order of the columns in the result tables is the same as the order of the
    parameters to the `select` method. So, you can re-order the columns with a
    second, chained call to `select`:

        tab1.select(:ref, :price, :shares, traded_on: :date, cost: 'price * shares') \
          .select(:ref, :traded_on, :price, :shares, :cost) \
          .to_aoa

        | Ref  |  Traded On | Price | Shares |     Cost |
        |------|------------|-------|--------|----------|
        | T001 | 2016-11-01 |   7.7 |    100 |    770.0 |
        | T002 | 2016-11-01 |  7.75 |    200 |   1550.0 |
        | T003 | 2016-11-01 |   7.5 |    800 |   6000.0 |
        | T003 | 2016-11-01 |   7.5 |    800 |   6000.0 |
        |------|------------|-------|--------|----------|
        | T004 | 2016-11-01 |  7.55 |   6811 | 51423.05 |
        | T005 | 2016-11-01 |   7.5 |   4000 |  30000.0 |
        | T006 | 2016-11-01 |   7.6 |   1000 |   7600.0 |
        | T006 | 2016-11-01 |   7.6 |   1000 |   7600.0 |
        | T007 | 2016-11-01 |  7.65 |    200 |   1530.0 |
        | T008 | 2016-11-01 |  7.65 |   2771 | 21198.15 |
        | T009 | 2016-11-01 |   7.6 |   9550 |  72580.0 |
        |------|------------|-------|--------|----------|
        | T010 | 2016-11-01 |  7.55 |   3175 | 23971.25 |
        | T011 | 2016-11-02 | 7.425 |    100 |    742.5 |
        | T012 | 2016-11-02 |  7.55 |   4700 |  35485.0 |
        | T012 | 2016-11-02 |  7.55 |   4700 |  35485.0 |
        | T013 | 2016-11-02 |  7.35 |  53100 | 390285.0 |
        |------|------------|-------|--------|----------|
        | T014 | 2016-11-02 |  7.45 |   5847 | 43560.15 |
        | T015 | 2016-11-02 |  7.75 |    500 |   3875.0 |
        | T016 | 2016-11-02 |  8.25 |    100 |    825.0 |

3.  Custom Instance Variables and Hooks

    As the above examples demonstrate, the instance variables `@row` and `@group`
    are available when evaluating expressions that add new columns. You can also set
    up your own instance variables as well for keeping track of things that cross
    row boundaries, such as running sums.

    To declare instance variables, you can use the `ivars:` hash parameter to
    `select`.  Each key of the hash becomes an instance variable and each value
    becomes its initial value before any rows are evaluated.

    In addition, you can provide `before_hook:` and `after_hook:` parameters to
    `select` as strings that are evaluated as ruby expressions before and after each
    row is processed. You can use these to update instance variables. The values set
    in the `before_hook:` can be used in expressions for adding new columns by
    referencing them with the &rsquo;@&rsquo; prefix.

    For example, suppose we wanted to not only add a cost column, but a column that
    shows the cumulative cost after each transaction in our example table. The
    following example uses the `ivars:` and `before_hook:` parameters to keep track
    of the running cost of shares, then formats the table.

        tab = tab1.select(:ref, :price, :shares, traded_on: :date, \
                    cost: 'price * shares', cumulative: '@total_cost', \
                    ivars: { total_cost: 0 }, \
                    before_hook: '@total_cost += price * shares')
        FatTable.to_aoa(tab) do |f|
          f.format(price: '0.4', shares: '0.0,', cost: '0.2,', cumulative: '0.2,')
        end

        | Ref  |  Price | Shares |  Traded On |       Cost | Cumulative |
        |------|--------|--------|------------|------------|------------|
        | T001 | 7.7000 |    100 | 2016-11-01 |     770.00 |     770.00 |
        | T002 | 7.7500 |    200 | 2016-11-01 |   1,550.00 |   2,320.00 |
        | T003 | 7.5000 |    800 | 2016-11-01 |   6,000.00 |   8,320.00 |
        | T003 | 7.5000 |    800 | 2016-11-01 |   6,000.00 |  14,320.00 |
        |------|--------|--------|------------|------------|------------|
        | T004 | 7.5500 |  6,811 | 2016-11-01 |  51,423.05 |  65,743.05 |
        | T005 | 7.5000 |  4,000 | 2016-11-01 |  30,000.00 |  95,743.05 |
        | T006 | 7.6000 |  1,000 | 2016-11-01 |   7,600.00 | 103,343.05 |
        | T006 | 7.6000 |  1,000 | 2016-11-01 |   7,600.00 | 110,943.05 |
        | T007 | 7.6500 |    200 | 2016-11-01 |   1,530.00 | 112,473.05 |
        | T008 | 7.6500 |  2,771 | 2016-11-01 |  21,198.15 | 133,671.20 |
        | T009 | 7.6000 |  9,550 | 2016-11-01 |  72,580.00 | 206,251.20 |
        |------|--------|--------|------------|------------|------------|
        | T010 | 7.5500 |  3,175 | 2016-11-01 |  23,971.25 | 230,222.45 |
        | T011 | 7.4250 |    100 | 2016-11-02 |     742.50 | 230,964.95 |
        | T012 | 7.5500 |  4,700 | 2016-11-02 |  35,485.00 | 266,449.95 |
        | T012 | 7.5500 |  4,700 | 2016-11-02 |  35,485.00 | 301,934.95 |
        | T013 | 7.3500 | 53,100 | 2016-11-02 | 390,285.00 | 692,219.95 |
        |------|--------|--------|------------|------------|------------|
        | T014 | 7.4500 |  5,847 | 2016-11-02 |  43,560.15 | 735,780.10 |
        | T015 | 7.7500 |    500 | 2016-11-02 |   3,875.00 | 739,655.10 |
        | T016 | 8.2500 |    100 | 2016-11-02 |     825.00 | 740,480.10 |

4.  Argument Order and Boundaries

    Notice that `select` can take any number of arguments but all the symbol
    arguments must come first followed by all the hash-like keyword arguments,
    including the special arguments for instance variables and hooks.

    As the example illustrates, `.select` transmits any group boundaries in its
    input table to the result table.


<a id="orge185ad7"></a>

### Where

You can filter the rows of the result table with the `.where` method. It takes a
single string expression as an argument which is evaluated in a manner similar
to `.select` in which the value of the cells in each column are available as
local variables and the instance variables `@row` and `@group` are available for
testing. The expression is evaluated for each row, and if the expression
evaluates to a truthy value, the row is included in the output, otherwise it is
not. The `.where` method obliterates any group boundaries in the input, so the
output table has only a single group.

Here we select only those even-numbered rows where either of the two boolean
fields is true:

    tab1.where('@row.even? && (g10 || qp10)') \
      .to_aoa

    | Ref  |       Date | Code | Price | G10 | QP10 | Shares |   Lp |    Qp |   Iplp |   Ipqp |
    |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
    | T002 | 2016-11-01 | P    |  7.75 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
    | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
    | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
    | T010 | 2016-11-01 | P    |  7.55 | F   | T    |   3175 |  451 |  2724 | 0.2453 | 0.1924 |
    | T013 | 2016-11-02 | P    |  7.35 | T   | T    |  53100 | 7656 | 45444 | 0.2453 | 0.1924 |


<a id="org57f51d1"></a>

### Order\_by

You can sort a table on any number of columns with `order_by`. The `order_by`
method takes any number of symbol arguments for the columns to sort on. If you
specify more than one column, the sort is performed on the first column, then
all columns that are equal with respect to the first column are sorted by the
second column, and so on. All columns of the input table are included in the
output.

Let&rsquo;s sort our table first by `:code`, then by `:date`.

    tab1.order_by(:code, :date) \
      .to_aoa

    | Ref  |       Date | Code | Price | G10 | QP10 | Shares |   Lp |    Qp |   Iplp |   Ipqp |
    |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
    | T001 | 2016-11-01 | P    |   7.7 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    | T002 | 2016-11-01 | P    |  7.75 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
    | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
    | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
    | T008 | 2016-11-01 | P    |  7.65 | F   | F    |   2771 |  393 |  2378 | 0.2453 | 0.1924 |
    | T009 | 2016-11-01 | P    |   7.6 | F   | F    |   9550 | 1363 |  8187 | 0.2453 | 0.1924 |
    | T010 | 2016-11-01 | P    |  7.55 | F   | T    |   3175 |  451 |  2724 | 0.2453 | 0.1924 |
    |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
    | T011 | 2016-11-02 | P    | 7.425 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
    | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
    | T013 | 2016-11-02 | P    |  7.35 | T   | T    |  53100 | 7656 | 45444 | 0.2453 | 0.1924 |
    | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 |  835 |  5012 | 0.2453 | 0.1924 |
    | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |   72 |   428 | 0.2453 | 0.1924 |
    | T016 | 2016-11-02 | P    |  8.25 | T   | T    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
    | T004 | 2016-11-01 | S    |  7.55 | T   | F    |   6811 |  966 |  5845 | 0.2453 | 0.1924 |
    | T005 | 2016-11-01 | S    |   7.5 | F   | F    |   4000 |  572 |  3428 | 0.2453 | 0.1924 |
    | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
    | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
    | T007 | 2016-11-01 | S    |  7.65 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |

The interesting thing about `order_by` is that, while it ignores groups in its
input, it adds group boundaries in the output table at those rows where the sort
keys change.  Thus, in each group, `:code` and `:date` are the same, and when
either changes, `order_by` inserts a group boundary.


<a id="org1ee0a85"></a>

### Group\_by

Like `order_by`, `group_by` takes a set of parameters of column header symbols,
the &ldquo;grouping parameters&rdquo;, by which to sort the table into a set of groups that
are equal with respect to values in those columns. In addition, those parameters
can be followed by a series of hash-like parameters, the &ldquo;aggregating
parameters&rdquo;, that indicate how any of the remaining, non-group columns are to be
aggregated into a single value. The output table has one row for each group for
which the grouping parameters are equal containing those columns and an
aggregate column for each of the aggregating parameters.

For example, let&rsquo;s summarize the `trades` table by `:code` and `:price` again,
and determine total shares, average price, and a few other features of each
group:

    tab1.group_by(:code, :date, price: :avg,
                  shares: :sum, lp: :sum, qp: :sum,
                  qp10: :all?) \
      .to_aoa { |f| f.format(avg_price: '0.5R') }

    | Code |       Date | Avg Price | Sum Shares | Sum Lp | Sum Qp | All QP10 |
    |------|------------|-----------|------------|--------|--------|----------|
    | P    | 2016-11-01 |   7.60714 |      17396 |   2473 |  14923 | F        |
    | P    | 2016-11-02 |   7.61786 |      69047 |   9945 |  59102 | F        |
    | S    | 2016-11-01 |   7.58000 |      13011 |   1852 |  11159 | F        |

After the grouping column parameters, `:code` and `:date`, there are several
hash-like &ldquo;aggregating&rdquo; parameters where the key is the column to aggregate and
the value is a symbol for one of several aggregating methods that
`FatTable::Column` objects understand. For example, the `:avg` method is applied
to the :price column so that the output shows the average price in each group.
The `:shares`, `:lp`, and `:qp` columns are summed, and the `:any?` aggregate is
applied to one of the boolean fields, that is, it is `true` if any of the values
in that column are `true`. The column names in the output of the aggregated
columns have the name of the aggregating method pre-pended to the column name.

Here is a list of all the aggregate methods available.  If the description
restricts the aggregate to particular column types, applying it to other types
will raise an exception.

-   **`first`:** the first non-nil item in the column,
-   **`last`:** the last non-nil item in the column,
-   **`rng`:** form a string of the form `"#{first}..#{last}"` to show the range of
    values in the column,
-   **`sum`:** for `Numeric` and `String` columns, apply &rsquo;+&rsquo; to all the non-nil
    values,
-   **`count`:** the number of non-nil values in the column,
-   **`min`:** for `Numeric`, `String`, and `DateTime` columns, return the smallest
    non-nil value in the column,
-   **`max`:** for `Numeric`, `String`, and `DateTime` columns, return the largest
    non-nil value in the column,
-   **`avg`:** for `Numeric` and `DateTime` columns, return the arithmetic mean of
    the non-nil values in the column; with respect to `Date` or `DateTime`
    objects, each is converted to a numeric Julian date, the average is
    calculated, and the result converted back to a `Date` or `DateTime` object,
-   **`var`:** for `Numeric` and `DateTime` columns, compute the sample variance of
    the non-nil values in the column, dates are converted to Julian date
    numbers as for the `:avg` aggregate,
-   **`pvar`:** for `Numeric` and `DateTime` columns, compute the population
    variance of the non-nil values in the column, dates are converted to Julian
    date numbers as for the `:avg` aggregate,
-   **`dev`:** for `Numeric` and `DateTime` columns, compute the sample standard
    deviation of the non-nil values in the column, dates are converted to
    Julian date numbers as for the `:avg` aggregate,
-   **`pdev`:** for `Numeric` and `DateTime` columns, compute the population
    standard deviation of the non-nil values in the column, dates are converted
    to numbers as for the `:avg` aggregate,
-   **`all?`:** for `Boolean` columns only, return true if all of the non-nil values
    in the column are true,
-   **`any?`:** for `Boolean` columns only, return true if any non-nil value in the
    column is true,
-   **`none?`:** for `Boolean` columns only, return true if no non-nil value in the
    column is true,
-   **`one?`:** for `Boolean` columns only, return true if exactly one non-nil value
    in the column is true,

Perhaps surprisingly, the `group_by` method ignores any groups in its input and
results in no group boundaries in the output since each group formed by the
implicit `order_by` on the grouping columns is collapsed into a single row.


<a id="org6432f26"></a>

### Join

1.  Join Types

    So far, all the operations have operated on a single table. `FatTable` provides
    several `join` methods for combining two tables, each of which takes as
    parameters (1) a second table and (2) except in the case of `cross_join`, zero
    or more &ldquo;join expressions&rdquo;. In the descriptions below, `T1` is the table on
    which the method is called, `T2` is the table supplied as the first parameter
    `other`, and `R1` and `R2` are rows in their respective tables being considered
    for inclusion in the joined output table.

    -   **`join(other, *jexps)`:** Performs an &ldquo;inner join&rdquo; on the tables. For each row
        `R1` of `T1`, the joined table has a row for each row in `T2` that
        satisfies the join condition with `R1`.

    -   **`left_join(other, *jexps)`:** First, an inner join is performed. Then, for
        each row in `T1` that does not satisfy the join condition with any row in
        `T2`, a joined row is added with null values in columns of `T2`. Thus, the
        joined table always has at least one row for each row in `T1`.

    -   **`right_join(other, *jexps)`:** First, an inner join is performed. Then, for
        each row in `T2` that does not satisfy the join condition with any row in
        `T1`, a joined row is added with null values in columns of `T1`. This is
        the converse of a left join: the result table will always have a row for
        each row in `T2`.

    -   **`full_join(other, *jexps)`:** First, an inner join is performed. Then, for
        each row in `T1` that does not satisfy the join condition with any row in
        `T2`, a joined row is added with null values in columns of `T2`. Also, for
        each row of `T2` that does not satisfy the join condition with any row in
        `T1`, a joined row with null values in the columns of `T1` is added.

    -   **`cross_join(other)`:** For every possible combination of rows from `T1` and
        `T2` (i.e., a Cartesian product), the joined table will contain a row
        consisting of all columns in `T1` followed by all columns in `T2`. If the
        tables have `N` and `M` rows respectively, the joined table will have `N *
             M` rows.

2.  Join Expressions

    For each of the join types, if no join expressions are given, the tables will be
    joined on columns having the same column header in both tables, and the join
    condition is satisfied when all the values in those columns are equal. If the
    join type is an inner join, this is a so-called &ldquo;natural&rdquo; join.

    If the join expressions are one or more symbols, the join condition requires
    that the values of both tables are equal for all columns named by the symbols. A
    column that appears in both tables can be given without modification and will be
    assumed to require equality on that column. If an unmodified symbol is not a
    name that appears in both tables, an exception will be raised. Column names that
    are unique to the first table must have a `_a` appended to the column name and
    column names that are unique to the other table must have a `_b` appended to the
    column name. These disambiguated column names must come in pairs, one for the
    first table and one for the second, and they will imply a join condition that
    the columns must be equal on those columns. Several such symbol expressions will
    require that all such implied pairs are equal in order for the join condition to
    be met.

    Finally, a join expression can be a string that contains an arbitrary ruby
    expression that will be evaluated for truthiness. Within the string, *all*
    column names must be disambiguated with the `_a` or `_b` modifiers whether they
    are common to both tables or not. As with `select` and `where` methods, the
    names of the columns in both tables (albeit disambiguated) are available as
    local variables within the expression, but the instance variables `@row` and
    `@group` are not.

3.  Join Examples

    The following examples are taken from the [Postgresql tutorial](https://www.tutorialspoint.com/postgresql/postgresql_using_joins.htm), with some slight
    modifications. The examples will use the following two tables, which are also
    available in `ft_console` as `@tab_a` and `@tab_b`:

        require 'fat_table'

            tab_a_str = <<-EOS
          | Id | Name  | Age | Address    | Salary |  Join Date |
          |----|-------|-----|------------|--------|------------|
          |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |
          |  3 | Teddy |  23 | Norway     |  20000 | 2007-12-13 |
          |  4 | Mark  |  25 | Rich-Mond  |  65000 | 2007-12-13 |
          |  5 | David |  27 | Texas      |  85000 | 2007-12-13 |
          |  2 | Allen |  25 | Texas      |        | 2005-07-13 |
          |  8 | Paul  |  24 | Houston    |  20000 | 2005-07-13 |
          |  9 | James |  44 | Norway     |   5000 | 2005-07-13 |
          | 10 | James |  45 | Texas      |   5000 |            |
          EOS

            tab_b_str = <<-EOS
          | Id | Dept        | Emp Id |
          |----|-------------|--------|
          |  1 | IT Billing  |      1 |
          |  2 | Engineering |      2 |
          |  3 | Finance     |      7 |
          EOS

            tab_a = FatTable.from_org_string(tab_a_str)
            tab_b = FatTable.from_org_string(tab_b_str)

    1.  Inner Joins

        With no join expression arguments, the tables are joined when their sole common
        field, `:id`, is equal in both tables.  The result is the natural join of the
        two tables.

            tab_a.join(tab_b).to_aoa

            | Id | Name  | Age | Address    | Salary |  Join Date | Dept        | Emp Id |
            |----|-------|-----|------------|--------|------------|-------------|--------|
            |  1 | Paul  |  32 | California |  20000 | 2001-07-13 | IT Billing  |      1 |
            |  3 | Teddy |  23 | Norway     |  20000 | 2007-12-13 | Finance     |      7 |
            |  2 | Allen |  25 | Texas      |        | 2005-07-13 | Engineering |      2 |

        But the natural join joined employee IDs in the first table and department IDs
        in the second table. To correct this, we need to explicitly state the columns we
        want to join on in each table by disambiguating them with `_a` and `_b`
        suffixes:

            tab_a.join(tab_b, :id_a, :emp_id_b).to_aoa

            | Id | Name  | Age | Address    | Salary |  Join Date | Id B | Dept        |
            |----|-------|-----|------------|--------|------------|------|-------------|
            |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |    1 | IT Billing  |
            |  2 | Allen |  25 | Texas      |        | 2005-07-13 |    2 | Engineering |

        Instead of using the disambiguated column names as symbols, we could also use a
        string containing a ruby expression.  Within the expression, the column names
        should be treated as local variables:

            tab_a.join(tab_b, 'id_a == emp_id_b').to_aoa

            | Id | Name  | Age | Address    | Salary |  Join Date | Id B | Dept        | Emp Id |
            |----|-------|-----|------------|--------|------------|------|-------------|--------|
            |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |    1 | IT Billing  |      1 |
            |  2 | Allen |  25 | Texas      |        | 2005-07-13 |    2 | Engineering |      2 |

    2.  Left and Right Joins

        In left join, all the rows of `tab_a` are included in the output, augmented by
        the matching columns of `tab_b` and augmented with nils where there is no match:

            tab_a.left_join(tab_b, 'id_a == emp_id_b').to_aoa

            | Id | Name  | Age | Address    | Salary |  Join Date | Id B | Dept        | Emp Id |
            |----|-------|-----|------------|--------|------------|------|-------------|--------|
            |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |    1 | IT Billing  |      1 |
            |  3 | Teddy |  23 | Norway     |  20000 | 2007-12-13 |      |             |        |
            |  4 | Mark  |  25 | Rich-Mond  |  65000 | 2007-12-13 |      |             |        |
            |  5 | David |  27 | Texas      |  85000 | 2007-12-13 |      |             |        |
            |  2 | Allen |  25 | Texas      |        | 2005-07-13 |    2 | Engineering |      2 |
            |  8 | Paul  |  24 | Houston    |  20000 | 2005-07-13 |      |             |        |
            |  9 | James |  44 | Norway     |   5000 | 2005-07-13 |      |             |        |
            | 10 | James |  45 | Texas      |   5000 |            |      |             |        |

        In a right join, all the rows of `tab_b` are included in the output, augmented
        by the matching columns of `tab_a` and augmented with nils where there is no
        match:

            tab_a.right_join(tab_b, 'id_a == emp_id_b').to_aoa

            | Id | Name  | Age | Address    | Salary |  Join Date | Id B | Dept        | Emp Id |
            |----|-------|-----|------------|--------|------------|------|-------------|--------|
            |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |    1 | IT Billing  |      1 |
            |  2 | Allen |  25 | Texas      |        | 2005-07-13 |    2 | Engineering |      2 |
            |    |       |     |            |        |            |    3 | Finance     |      7 |

    3.  Full Join

        A full join combines the effects of a left join and a right join. All the rows
        from both tables are included in the output augmented by columns of the other
        table where the join expression is satisfied and augmented with nils otherwise.

            tab_a.full_join(tab_b, 'id_a == emp_id_b').to_aoa

            | Id | Name  | Age | Address    | Salary |  Join Date | Id B | Dept        | Emp Id |
            |----|-------|-----|------------|--------|------------|------|-------------|--------|
            |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |    1 | IT Billing  |      1 |
            |  3 | Teddy |  23 | Norway     |  20000 | 2007-12-13 |      |             |        |
            |  4 | Mark  |  25 | Rich-Mond  |  65000 | 2007-12-13 |      |             |        |
            |  5 | David |  27 | Texas      |  85000 | 2007-12-13 |      |             |        |
            |  2 | Allen |  25 | Texas      |        | 2005-07-13 |    2 | Engineering |      2 |
            |  8 | Paul  |  24 | Houston    |  20000 | 2005-07-13 |      |             |        |
            |  9 | James |  44 | Norway     |   5000 | 2005-07-13 |      |             |        |
            | 10 | James |  45 | Texas      |   5000 |            |      |             |        |
            |    |       |     |            |        |            |    3 | Finance     |      7 |

    4.  Cross Join

        Finally, a cross join outputs every row of `tab_a` augmented with every row of
        `tab_b`, in other words, the Cartesian product of the two tables. If `tab_a` has
        `N` rows and `tab_b` has `M` rows, the output table will have `N * M` rows.

            tab_a.cross_join(tab_b).to_aoa

            | Id | Name  | Age | Address    | Salary |  Join Date | Id B | Dept        | Emp Id |
            |----|-------|-----|------------|--------|------------|------|-------------|--------|
            |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |    1 | IT Billing  |      1 |
            |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |    2 | Engineering |      2 |
            |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |    3 | Finance     |      7 |
            |  3 | Teddy |  23 | Norway     |  20000 | 2007-12-13 |    1 | IT Billing  |      1 |
            |  3 | Teddy |  23 | Norway     |  20000 | 2007-12-13 |    2 | Engineering |      2 |
            |  3 | Teddy |  23 | Norway     |  20000 | 2007-12-13 |    3 | Finance     |      7 |
            |  4 | Mark  |  25 | Rich-Mond  |  65000 | 2007-12-13 |    1 | IT Billing  |      1 |
            |  4 | Mark  |  25 | Rich-Mond  |  65000 | 2007-12-13 |    2 | Engineering |      2 |
            |  4 | Mark  |  25 | Rich-Mond  |  65000 | 2007-12-13 |    3 | Finance     |      7 |
            |  5 | David |  27 | Texas      |  85000 | 2007-12-13 |    1 | IT Billing  |      1 |
            |  5 | David |  27 | Texas      |  85000 | 2007-12-13 |    2 | Engineering |      2 |
            |  5 | David |  27 | Texas      |  85000 | 2007-12-13 |    3 | Finance     |      7 |
            |  2 | Allen |  25 | Texas      |        | 2005-07-13 |    1 | IT Billing  |      1 |
            |  2 | Allen |  25 | Texas      |        | 2005-07-13 |    2 | Engineering |      2 |
            |  2 | Allen |  25 | Texas      |        | 2005-07-13 |    3 | Finance     |      7 |
            |  8 | Paul  |  24 | Houston    |  20000 | 2005-07-13 |    1 | IT Billing  |      1 |
            |  8 | Paul  |  24 | Houston    |  20000 | 2005-07-13 |    2 | Engineering |      2 |
            |  8 | Paul  |  24 | Houston    |  20000 | 2005-07-13 |    3 | Finance     |      7 |
            |  9 | James |  44 | Norway     |   5000 | 2005-07-13 |    1 | IT Billing  |      1 |
            |  9 | James |  44 | Norway     |   5000 | 2005-07-13 |    2 | Engineering |      2 |
            |  9 | James |  44 | Norway     |   5000 | 2005-07-13 |    3 | Finance     |      7 |
            | 10 | James |  45 | Texas      |   5000 |            |    1 | IT Billing  |      1 |
            | 10 | James |  45 | Texas      |   5000 |            |    2 | Engineering |      2 |
            | 10 | James |  45 | Texas      |   5000 |            |    3 | Finance     |      7 |


<a id="org7d2857d"></a>

### Set Operations

`FatTable` can perform several set operations on tables. In order for two tables
to be used this way, they must have the same number of columns with the same
types or an exception will be raised. We&rsquo;ll call two tables that qualify for
combining with set operations &ldquo;set-compatible.&rdquo;

We&rsquo;ll use the following two set-compatible tables in the examples. They each
have some duplicates and some group boundaries so you can see the effect of the
set operations on duplicates and groups.

    tab1.to_aoa

    | Ref  |       Date | Code | Price | G10 | QP10 | Shares |   Lp |    Qp |   Iplp |   Ipqp |
    |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
    | T001 | 2016-11-01 | P    |   7.7 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    | T002 | 2016-11-01 | P    |  7.75 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
    | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
    | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
    |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
    | T004 | 2016-11-01 | S    |  7.55 | T   | F    |   6811 |  966 |  5845 | 0.2453 | 0.1924 |
    | T005 | 2016-11-01 | S    |   7.5 | F   | F    |   4000 |  572 |  3428 | 0.2453 | 0.1924 |
    | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
    | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
    | T007 | 2016-11-01 | S    |  7.65 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
    | T008 | 2016-11-01 | P    |  7.65 | F   | F    |   2771 |  393 |  2378 | 0.2453 | 0.1924 |
    | T009 | 2016-11-01 | P    |   7.6 | F   | F    |   9550 | 1363 |  8187 | 0.2453 | 0.1924 |
    |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
    | T010 | 2016-11-01 | P    |  7.55 | F   | T    |   3175 |  451 |  2724 | 0.2453 | 0.1924 |
    | T011 | 2016-11-02 | P    | 7.425 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
    | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
    | T013 | 2016-11-02 | P    |  7.35 | T   | T    |  53100 | 7656 | 45444 | 0.2453 | 0.1924 |
    |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
    | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 |  835 |  5012 | 0.2453 | 0.1924 |
    | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |   72 |   428 | 0.2453 | 0.1924 |
    | T016 | 2016-11-02 | P    |  8.25 | T   | T    |    100 |   14 |    86 | 0.2453 | 0.1924 |

    tab2.to_aoa

    | Ref  |       Date | Code | Price | G10 | QP10 | Shares |    Lp |   Qp |   Iplp |   Ipqp |
    |------|------------|------|-------|-----|------|--------|-------|------|--------|--------|
    | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |   112 |  688 | 0.2453 | 0.1924 |
    | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |   112 |  688 | 0.2453 | 0.1924 |
    | T017 | 2016-11-01 | P    |   8.3 | F   | T    |   1801 |  1201 |  600 | 0.2453 | 0.1924 |
    |------|------------|------|-------|-----|------|--------|-------|------|--------|--------|
    | T018 | 2016-11-01 | S    | 7.152 | T   | F    |   2516 |  2400 |  116 | 0.2453 | 0.1924 |
    | T018 | 2016-11-01 | S    | 7.152 | T   | F    |   2516 |  2400 |  116 | 0.2453 | 0.1924 |
    | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |   143 |  857 | 0.2453 | 0.1924 |
    | T007 | 2016-11-01 | S    |  7.65 | T   | F    |    200 |    28 |  172 | 0.2453 | 0.1924 |
    |------|------------|------|-------|-----|------|--------|-------|------|--------|--------|
    | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 |   835 | 5012 | 0.2453 | 0.1924 |
    | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |    72 |  428 | 0.2453 | 0.1924 |
    | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |    72 |  428 | 0.2453 | 0.1924 |
    | T016 | 2016-11-02 | P    |  8.25 | T   | T    |    100 |    14 |   86 | 0.2453 | 0.1924 |
    |------|------------|------|-------|-----|------|--------|-------|------|--------|--------|
    | T019 | 2017-01-15 | S    |  8.75 | T   | F    |    300 |   175 |  125 | 0.2453 | 0.1924 |
    | T020 | 2017-01-19 | S    |  8.25 | F   | T    |    700 |   615 |   85 | 0.2453 | 0.1924 |
    | T021 | 2017-01-23 | P    |  7.16 | T   | T    |  12100 | 11050 | 1050 | 0.2453 | 0.1924 |
    | T021 | 2017-01-23 | P    |  7.16 | T   | T    |  12100 | 11050 | 1050 | 0.2453 | 0.1924 |

1.  Unions

    Two tables that are set-compatible can be combined with the `union` or
    `union_all` methods so that the rows of both tables appear in the output. In the
    output table, the headers of the receiver table are used. You can use `select`
    to change or re-order the headers if you prefer. The `union` method eliminates
    duplicate rows in the result table, the `union_all` method does not.

    Any group boundaries in the input tables are destroyed by `union` but are
    preserved by `union_all`. In addition, `union_all` (but not `union`) adds a
    group boundary between the rows of the two input tables.

        tab1.union(tab2).to_aoa

        | Ref  |       Date | Code | Price | G10 | QP10 | Shares |    Lp |    Qp |   Iplp |   Ipqp |
        |------|------------|------|-------|-----|------|--------|-------|-------|--------|--------|
        | T001 | 2016-11-01 | P    |   7.7 | T   | F    |    100 |    14 |    86 | 0.2453 | 0.1924 |
        | T002 | 2016-11-01 | P    |  7.75 | T   | F    |    200 |    28 |   172 | 0.2453 | 0.1924 |
        | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |   112 |   688 | 0.2453 | 0.1924 |
        | T004 | 2016-11-01 | S    |  7.55 | T   | F    |   6811 |   966 |  5845 | 0.2453 | 0.1924 |
        | T005 | 2016-11-01 | S    |   7.5 | F   | F    |   4000 |   572 |  3428 | 0.2453 | 0.1924 |
        | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |   143 |   857 | 0.2453 | 0.1924 |
        | T007 | 2016-11-01 | S    |  7.65 | T   | F    |    200 |    28 |   172 | 0.2453 | 0.1924 |
        | T008 | 2016-11-01 | P    |  7.65 | F   | F    |   2771 |   393 |  2378 | 0.2453 | 0.1924 |
        | T009 | 2016-11-01 | P    |   7.6 | F   | F    |   9550 |  1363 |  8187 | 0.2453 | 0.1924 |
        | T010 | 2016-11-01 | P    |  7.55 | F   | T    |   3175 |   451 |  2724 | 0.2453 | 0.1924 |
        | T011 | 2016-11-02 | P    | 7.425 | T   | F    |    100 |    14 |    86 | 0.2453 | 0.1924 |
        | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |   677 |  4023 | 0.2453 | 0.1924 |
        | T013 | 2016-11-02 | P    |  7.35 | T   | T    |  53100 |  7656 | 45444 | 0.2453 | 0.1924 |
        | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 |   835 |  5012 | 0.2453 | 0.1924 |
        | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |    72 |   428 | 0.2453 | 0.1924 |
        | T016 | 2016-11-02 | P    |  8.25 | T   | T    |    100 |    14 |    86 | 0.2453 | 0.1924 |
        | T017 | 2016-11-01 | P    |   8.3 | F   | T    |   1801 |  1201 |   600 | 0.2453 | 0.1924 |
        | T018 | 2016-11-01 | S    | 7.152 | T   | F    |   2516 |  2400 |   116 | 0.2453 | 0.1924 |
        | T019 | 2017-01-15 | S    |  8.75 | T   | F    |    300 |   175 |   125 | 0.2453 | 0.1924 |
        | T020 | 2017-01-19 | S    |  8.25 | F   | T    |    700 |   615 |    85 | 0.2453 | 0.1924 |
        | T021 | 2017-01-23 | P    |  7.16 | T   | T    |  12100 | 11050 |  1050 | 0.2453 | 0.1924 |

        tab1.union_all(tab2).to_aoa

        | Ref  |       Date | Code | Price | G10 | QP10 | Shares |    Lp |    Qp |   Iplp |   Ipqp |
        |------|------------|------|-------|-----|------|--------|-------|-------|--------|--------|
        | T001 | 2016-11-01 | P    |   7.7 | T   | F    |    100 |    14 |    86 | 0.2453 | 0.1924 |
        | T002 | 2016-11-01 | P    |  7.75 | T   | F    |    200 |    28 |   172 | 0.2453 | 0.1924 |
        | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |   112 |   688 | 0.2453 | 0.1924 |
        | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |   112 |   688 | 0.2453 | 0.1924 |
        |------|------------|------|-------|-----|------|--------|-------|-------|--------|--------|
        | T004 | 2016-11-01 | S    |  7.55 | T   | F    |   6811 |   966 |  5845 | 0.2453 | 0.1924 |
        | T005 | 2016-11-01 | S    |   7.5 | F   | F    |   4000 |   572 |  3428 | 0.2453 | 0.1924 |
        | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |   143 |   857 | 0.2453 | 0.1924 |
        | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |   143 |   857 | 0.2453 | 0.1924 |
        | T007 | 2016-11-01 | S    |  7.65 | T   | F    |    200 |    28 |   172 | 0.2453 | 0.1924 |
        | T008 | 2016-11-01 | P    |  7.65 | F   | F    |   2771 |   393 |  2378 | 0.2453 | 0.1924 |
        | T009 | 2016-11-01 | P    |   7.6 | F   | F    |   9550 |  1363 |  8187 | 0.2453 | 0.1924 |
        |------|------------|------|-------|-----|------|--------|-------|-------|--------|--------|
        | T010 | 2016-11-01 | P    |  7.55 | F   | T    |   3175 |   451 |  2724 | 0.2453 | 0.1924 |
        | T011 | 2016-11-02 | P    | 7.425 | T   | F    |    100 |    14 |    86 | 0.2453 | 0.1924 |
        | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |   677 |  4023 | 0.2453 | 0.1924 |
        | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |   677 |  4023 | 0.2453 | 0.1924 |
        | T013 | 2016-11-02 | P    |  7.35 | T   | T    |  53100 |  7656 | 45444 | 0.2453 | 0.1924 |
        |------|------------|------|-------|-----|------|--------|-------|-------|--------|--------|
        | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 |   835 |  5012 | 0.2453 | 0.1924 |
        | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |    72 |   428 | 0.2453 | 0.1924 |
        | T016 | 2016-11-02 | P    |  8.25 | T   | T    |    100 |    14 |    86 | 0.2453 | 0.1924 |
        |------|------------|------|-------|-----|------|--------|-------|-------|--------|--------|
        | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |   112 |   688 | 0.2453 | 0.1924 |
        | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |   112 |   688 | 0.2453 | 0.1924 |
        | T017 | 2016-11-01 | P    |   8.3 | F   | T    |   1801 |  1201 |   600 | 0.2453 | 0.1924 |
        |------|------------|------|-------|-----|------|--------|-------|-------|--------|--------|
        | T018 | 2016-11-01 | S    | 7.152 | T   | F    |   2516 |  2400 |   116 | 0.2453 | 0.1924 |
        | T018 | 2016-11-01 | S    | 7.152 | T   | F    |   2516 |  2400 |   116 | 0.2453 | 0.1924 |
        | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |   143 |   857 | 0.2453 | 0.1924 |
        | T007 | 2016-11-01 | S    |  7.65 | T   | F    |    200 |    28 |   172 | 0.2453 | 0.1924 |
        |------|------------|------|-------|-----|------|--------|-------|-------|--------|--------|
        | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 |   835 |  5012 | 0.2453 | 0.1924 |
        | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |    72 |   428 | 0.2453 | 0.1924 |
        | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |    72 |   428 | 0.2453 | 0.1924 |
        | T016 | 2016-11-02 | P    |  8.25 | T   | T    |    100 |    14 |    86 | 0.2453 | 0.1924 |
        |------|------------|------|-------|-----|------|--------|-------|-------|--------|--------|
        | T019 | 2017-01-15 | S    |  8.75 | T   | F    |    300 |   175 |   125 | 0.2453 | 0.1924 |
        | T020 | 2017-01-19 | S    |  8.25 | F   | T    |    700 |   615 |    85 | 0.2453 | 0.1924 |
        | T021 | 2017-01-23 | P    |  7.16 | T   | T    |  12100 | 11050 |  1050 | 0.2453 | 0.1924 |
        | T021 | 2017-01-23 | P    |  7.16 | T   | T    |  12100 | 11050 |  1050 | 0.2453 | 0.1924 |

2.  Intersections

    The `intersect` method returns a table having only rows common to both tables,
    eliminating any duplicate rows in the result.

        tab1.intersect(tab2).to_aoa

        | Ref  |       Date | Code | Price | G10 | QP10 | Shares |  Lp |   Qp |   Iplp |   Ipqp |
        |------|------------|------|-------|-----|------|--------|-----|------|--------|--------|
        | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 | 112 |  688 | 0.2453 | 0.1924 |
        | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 | 143 |  857 | 0.2453 | 0.1924 |
        | T007 | 2016-11-01 | S    |  7.65 | T   | F    |    200 |  28 |  172 | 0.2453 | 0.1924 |
        | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 | 835 | 5012 | 0.2453 | 0.1924 |
        | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |  72 |  428 | 0.2453 | 0.1924 |
        | T016 | 2016-11-02 | P    |  8.25 | T   | T    |    100 |  14 |   86 | 0.2453 | 0.1924 |

    With `intersect_all`, all the rows of the first table, including duplicates, are
    included in the result if they also occur in the second table. However,
    duplicates in the second table do not appear.

        tab1.intersect_all(tab2).to_aoa

        | Ref  |       Date | Code | Price | G10 | QP10 | Shares |  Lp |   Qp |   Iplp |   Ipqp |
        |------|------------|------|-------|-----|------|--------|-----|------|--------|--------|
        | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 | 112 |  688 | 0.2453 | 0.1924 |
        | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 | 112 |  688 | 0.2453 | 0.1924 |
        | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 | 143 |  857 | 0.2453 | 0.1924 |
        | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 | 143 |  857 | 0.2453 | 0.1924 |
        | T007 | 2016-11-01 | S    |  7.65 | T   | F    |    200 |  28 |  172 | 0.2453 | 0.1924 |
        | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 | 835 | 5012 | 0.2453 | 0.1924 |
        | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |  72 |  428 | 0.2453 | 0.1924 |
        | T016 | 2016-11-02 | P    |  8.25 | T   | T    |    100 |  14 |   86 | 0.2453 | 0.1924 |

    As a result, it makes a difference which table is the receiver of the
    `intersect_all` method call and which is the argument.  In other words, order of
    operation matters.

        tab2.intersect_all(tab1).to_aoa

        | Ref  |       Date | Code | Price | G10 | QP10 | Shares |  Lp |   Qp |   Iplp |   Ipqp |
        |------|------------|------|-------|-----|------|--------|-----|------|--------|--------|
        | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 | 112 |  688 | 0.2453 | 0.1924 |
        | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 | 112 |  688 | 0.2453 | 0.1924 |
        | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 | 143 |  857 | 0.2453 | 0.1924 |
        | T007 | 2016-11-01 | S    |  7.65 | T   | F    |    200 |  28 |  172 | 0.2453 | 0.1924 |
        | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 | 835 | 5012 | 0.2453 | 0.1924 |
        | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |  72 |  428 | 0.2453 | 0.1924 |
        | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |  72 |  428 | 0.2453 | 0.1924 |
        | T016 | 2016-11-02 | P    |  8.25 | T   | T    |    100 |  14 |   86 | 0.2453 | 0.1924 |

3.  Differences with Except

    You can use the `except` method to delete from a table any rows that occur in
    another table, that is, compute the set difference between the tables.

        tab1.except(tab2).to_aoa

        | Ref  |       Date | Code | Price | G10 | QP10 | Shares |   Lp |    Qp |   Iplp |   Ipqp |
        |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
        | T001 | 2016-11-01 | P    |   7.7 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
        | T002 | 2016-11-01 | P    |  7.75 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
        | T004 | 2016-11-01 | S    |  7.55 | T   | F    |   6811 |  966 |  5845 | 0.2453 | 0.1924 |
        | T005 | 2016-11-01 | S    |   7.5 | F   | F    |   4000 |  572 |  3428 | 0.2453 | 0.1924 |
        | T008 | 2016-11-01 | P    |  7.65 | F   | F    |   2771 |  393 |  2378 | 0.2453 | 0.1924 |
        | T009 | 2016-11-01 | P    |   7.6 | F   | F    |   9550 | 1363 |  8187 | 0.2453 | 0.1924 |
        | T010 | 2016-11-01 | P    |  7.55 | F   | T    |   3175 |  451 |  2724 | 0.2453 | 0.1924 |
        | T011 | 2016-11-02 | P    | 7.425 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
        | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
        | T013 | 2016-11-02 | P    |  7.35 | T   | T    |  53100 | 7656 | 45444 | 0.2453 | 0.1924 |

    Like subtraction, though, the order of operands matters with set difference
    computed by `except`.

        tab2.except(tab1).to_aoa

        | Ref  |       Date | Code | Price | G10 | QP10 | Shares |    Lp |   Qp |   Iplp |   Ipqp |
        |------|------------|------|-------|-----|------|--------|-------|------|--------|--------|
        | T017 | 2016-11-01 | P    |   8.3 | F   | T    |   1801 |  1201 |  600 | 0.2453 | 0.1924 |
        | T018 | 2016-11-01 | S    | 7.152 | T   | F    |   2516 |  2400 |  116 | 0.2453 | 0.1924 |
        | T019 | 2017-01-15 | S    |  8.75 | T   | F    |    300 |   175 |  125 | 0.2453 | 0.1924 |
        | T020 | 2017-01-19 | S    |  8.25 | F   | T    |    700 |   615 |   85 | 0.2453 | 0.1924 |
        | T021 | 2017-01-23 | P    |  7.16 | T   | T    |  12100 | 11050 | 1050 | 0.2453 | 0.1924 |

    As with `intersect_all`, `except_all` includes any duplicates in the first,
    receiver table, but not those in the second, argument table.

        tab1.except_all(tab2).to_aoa

        | Ref  |       Date | Code | Price | G10 | QP10 | Shares |   Lp |    Qp |   Iplp |   Ipqp |
        |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
        | T001 | 2016-11-01 | P    |   7.7 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
        | T002 | 2016-11-01 | P    |  7.75 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
        | T004 | 2016-11-01 | S    |  7.55 | T   | F    |   6811 |  966 |  5845 | 0.2453 | 0.1924 |
        | T005 | 2016-11-01 | S    |   7.5 | F   | F    |   4000 |  572 |  3428 | 0.2453 | 0.1924 |
        | T008 | 2016-11-01 | P    |  7.65 | F   | F    |   2771 |  393 |  2378 | 0.2453 | 0.1924 |
        | T009 | 2016-11-01 | P    |   7.6 | F   | F    |   9550 | 1363 |  8187 | 0.2453 | 0.1924 |
        | T010 | 2016-11-01 | P    |  7.55 | F   | T    |   3175 |  451 |  2724 | 0.2453 | 0.1924 |
        | T011 | 2016-11-02 | P    | 7.425 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
        | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
        | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
        | T013 | 2016-11-02 | P    |  7.35 | T   | T    |  53100 | 7656 | 45444 | 0.2453 | 0.1924 |

    And, of course, the order of operands matters here as well.

        tab2.except_all(tab1).to_aoa

        | Ref  |       Date | Code | Price | G10 | QP10 | Shares |    Lp |   Qp |   Iplp |   Ipqp |
        |------|------------|------|-------|-----|------|--------|-------|------|--------|--------|
        | T017 | 2016-11-01 | P    |   8.3 | F   | T    |   1801 |  1201 |  600 | 0.2453 | 0.1924 |
        | T018 | 2016-11-01 | S    | 7.152 | T   | F    |   2516 |  2400 |  116 | 0.2453 | 0.1924 |
        | T018 | 2016-11-01 | S    | 7.152 | T   | F    |   2516 |  2400 |  116 | 0.2453 | 0.1924 |
        | T019 | 2017-01-15 | S    |  8.75 | T   | F    |    300 |   175 |  125 | 0.2453 | 0.1924 |
        | T020 | 2017-01-19 | S    |  8.25 | F   | T    |    700 |   615 |   85 | 0.2453 | 0.1924 |
        | T021 | 2017-01-23 | P    |  7.16 | T   | T    |  12100 | 11050 | 1050 | 0.2453 | 0.1924 |
        | T021 | 2017-01-23 | P    |  7.16 | T   | T    |  12100 | 11050 | 1050 | 0.2453 | 0.1924 |


<a id="org073a8b5"></a>

### Uniq (aka Distinct)

The `uniq` method takes no arguments and simply removes any duplicate rows from
the input table.  The `distinct` method is an alias for `uniq`.  Any groups in
the input table are lost.

    tab1.uniq.to_aoa

    | Ref  |       Date | Code | Price | G10 | QP10 | Shares |   Lp |    Qp |   Iplp |   Ipqp |
    |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
    | T001 | 2016-11-01 | P    |   7.7 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    | T002 | 2016-11-01 | P    |  7.75 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
    | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
    | T004 | 2016-11-01 | S    |  7.55 | T   | F    |   6811 |  966 |  5845 | 0.2453 | 0.1924 |
    | T005 | 2016-11-01 | S    |   7.5 | F   | F    |   4000 |  572 |  3428 | 0.2453 | 0.1924 |
    | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
    | T007 | 2016-11-01 | S    |  7.65 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
    | T008 | 2016-11-01 | P    |  7.65 | F   | F    |   2771 |  393 |  2378 | 0.2453 | 0.1924 |
    | T009 | 2016-11-01 | P    |   7.6 | F   | F    |   9550 | 1363 |  8187 | 0.2453 | 0.1924 |
    | T010 | 2016-11-01 | P    |  7.55 | F   | T    |   3175 |  451 |  2724 | 0.2453 | 0.1924 |
    | T011 | 2016-11-02 | P    | 7.425 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
    | T013 | 2016-11-02 | P    |  7.35 | T   | T    |  53100 | 7656 | 45444 | 0.2453 | 0.1924 |
    | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 |  835 |  5012 | 0.2453 | 0.1924 |
    | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |   72 |   428 | 0.2453 | 0.1924 |
    | T016 | 2016-11-02 | P    |  8.25 | T   | T    |    100 |   14 |    86 | 0.2453 | 0.1924 |


<a id="orgd147303"></a>

### Remove groups with degroup!

Finally, it is sometimes helpful to remove any group boundaries from a table.
You can do this with `.degroup!`, which is the only operation that mutates its
receiver table by removing its groups.

    tab1.degroup!.to_aoa

    | Ref  |       Date | Code | Price | G10 | QP10 | Shares |   Lp |    Qp |   Iplp |   Ipqp |
    |------|------------|------|-------|-----|------|--------|------|-------|--------|--------|
    | T001 | 2016-11-01 | P    |   7.7 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    | T002 | 2016-11-01 | P    |  7.75 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
    | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
    | T003 | 2016-11-01 | P    |   7.5 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
    | T004 | 2016-11-01 | S    |  7.55 | T   | F    |   6811 |  966 |  5845 | 0.2453 | 0.1924 |
    | T005 | 2016-11-01 | S    |   7.5 | F   | F    |   4000 |  572 |  3428 | 0.2453 | 0.1924 |
    | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
    | T006 | 2016-11-01 | S    |   7.6 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
    | T007 | 2016-11-01 | S    |  7.65 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
    | T008 | 2016-11-01 | P    |  7.65 | F   | F    |   2771 |  393 |  2378 | 0.2453 | 0.1924 |
    | T009 | 2016-11-01 | P    |   7.6 | F   | F    |   9550 | 1363 |  8187 | 0.2453 | 0.1924 |
    | T010 | 2016-11-01 | P    |  7.55 | F   | T    |   3175 |  451 |  2724 | 0.2453 | 0.1924 |
    | T011 | 2016-11-02 | P    | 7.425 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
    | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
    | T012 | 2016-11-02 | P    |  7.55 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
    | T013 | 2016-11-02 | P    |  7.35 | T   | T    |  53100 | 7656 | 45444 | 0.2453 | 0.1924 |
    | T014 | 2016-11-02 | P    |  7.45 | F   | T    |   5847 |  835 |  5012 | 0.2453 | 0.1924 |
    | T015 | 2016-11-02 | P    |  7.75 | F   | F    |    500 |   72 |   428 | 0.2453 | 0.1924 |
    | T016 | 2016-11-02 | P    |  8.25 | T   | T    |    100 |   14 |    86 | 0.2453 | 0.1924 |


<a id="org9f4d633"></a>

## Formatting Tables

Besides creating and operating on tables, you may want to display the resulting
table. `FatTable` seeks to provide a set of formatting directives that are the
most common across many output media. It provides directives for alignment, for
color, for adding currency symbols and grouping commas to numbers, for padding
numbers, and for formatting dates and booleans.

In addition, you can add any number of footers to a table, which appear at the
end of the table, and any number of group footers, which appear after each group
in the table. These can be formatted independently of the table body.

If the target output medium does not support a formatting directive or the
directive does not make sense, it is simply ignored. For example, you can output
an `org-mode` table as a String, and since `org-mode` does not support colors,
any color directives are ignored. Some of the output targets are not strings,
but ruby data structures, and for them, things such as alignment are irrelevant.


<a id="orgb7b2335"></a>

### Available Formatters

`FatTable` supports the following output targets for its tables:

-   **Text:** form the table with ACSII characters,
-   **Org:** form the table with ASCII characters but in the form used by Emacs
    org-mode for constructing tables,
-   **Term:** form the table with ANSI terminal codes and unicode characters,
    possibly including colored text and cell backgrounds,
-   **LaTeX:** form the table as input for LaTeX&rsquo;s longtable environment,
-   **Aoh:** output the table as a ruby data structure, building the table as an
    array of hashes, and
-   **Aoa:** output the table as a ruby data structure, building the table as an
    array of array,

These are all implemented by classes that inherit from `FatTable::Formatter`
class by defining about a dozen methods that get called at various places during
the construction of the output table. The idea is that more classes can be
defined by adding additional classes.


<a id="org4db9ae4"></a>

### Table Locations

In the formatting methods, the table is divided into several &ldquo;locations&rdquo; for
which separate formatting directives may be given. These locations are
identified with the following symbols:

-   **:header:** the first row of the output table containing the headers,
-   **:footer:** all rows of the table&rsquo;s footers,
-   **:gfooter:** all rows of the table&rsquo;s group footers,
-   **:body:** all the data rows of the table, that is, those that are neither part
    of the header, footers, or gfooters,
-   **:bfirst:** the first row of the table&rsquo;s body, and
-   **:gfirst:** the first row in each group in the table&rsquo;s body.


<a id="orgd2128a3"></a>

### Formatting Directives

The formatting methods explained in the next section all take formatting
directives as strings in which letters and other characters signify what
formatting applies.  For example, we may apply the formatting directive `'R,$'`
to numbers in a certain part of the table.  Each of those characters, and in
some cases a whole substring, is a single directive.  They can appear in any
order, so `'$R,'` and `',$R'` are equivalent.

Here is a list of all the formatting directives that apply to each cell type:

1.  String

    For a string element, the following instructions are valid. Note that these can
    also be applied to all the other cell types as well since they are all converted
    to a string in forming the output.

    -   **u:** convert the element to all lowercase,
    -   **U:** convert the element to all uppercase,
    -   **t:** title case the element, that is, upcase the initial letter in
        each word and lower case the other letters
    -   **B ~B:** make the element bold, or turn off bold
    -   **I ~I:** make the element italic, or turn off italic
    -   **R:** align the element on the right of the column
    -   **L:** align the element on the left of the column
    -   **C:** align the element in the center of the column
    -   **c[color]:** render the element in the given color; the color can have
        the form fgcolor, fgcolor.bgcolor, or .bgcolor, to set the
        foreground or background colors respectively, and each of those can
        be an ANSI or X11 color name in addition to the special color,
        &rsquo;none&rsquo;, which keeps the terminal&rsquo;s default color.
    -   **\_ ~\_:** underline the element, or turn off underline
    -   **\* ~\*:** cause the element to blink, or turn off blink

    For example, the directive `'tCc[red.yellow]'` would title-case the element,
    center it, and color it red on a yellow background. The directives that are
    boolean have negating forms so that, for example, if bold is turned on for all
    columns of a given type, it can be countermanded in formatting directives for
    particular columns.

2.  Numeric

    For a numeric element, all the instructions valid for string are available, in
    addition to the following:

    -   **, ~,:** insert grouping commas, or do not insert grouping commas,
    -   **$ ~$:** format the number as currency according to the locale, or not,
    -   **m.n:** include at least m digits before the decimal point, padding on
        the left with zeroes as needed, and round the number to the n
        decimal places and include n digits after the decimal point,
        padding on the right with zeroes as needed,
    -   **H:** convert the number (assumed to be in units of seconds) to `HH:MM:SS.ss`
        form. So a column that is the result of subtracting two :datetime forms
        will result in a :numeric expressed as seconds and can be displayed in
        hours, minutes, and seconds with this formatting instruction.

    For example, the directive `'R5.0c[blue]'` would right-align the numeric
    element, pad it on the left with zeros, and color it blue.

3.  DateTime

    For a `DateTime`, all the instructions valid for string are available, in
    addition to the following:

    -   **d[fmt]:** apply the format to a `Date` or a  `DateTime` that is a whole day,
        that is that has no or zero hour, minute, and second components, where fmt
        is a valid format string for `Date#strftime`, otherwise, the datetime will
        be formatted as an ISO 8601 string, YYYY-MM-DD.
    -   **D[fmt]:** apply the format to a datetime that has at least a non-zero hour
        component where fmt is a valid format string for Date#strftime, otherwise,
        the datetime will be formatted as an ISO 8601 string, YYYY-MM-DD.

    For example, `'c[pink]d[%b %-d, %Y]C'`, would format a date element like &rsquo;Sep
    22, 1957&rsquo;, center it, and color it pink.

4.  Boolean

    For a boolean cell, all the instructions valid for string are available, in
    addition to the following:

    -   **Y:** print true as &rsquo;`Y`&rsquo; and false as &rsquo;`N`&rsquo;,
    -   **T:** print true as &rsquo;`T`&rsquo; and false as &rsquo;`F`&rsquo;,
    -   **X:** print true as &rsquo;`X`&rsquo; and false as an empty string &rsquo;&rsquo;,
    -   **b[xxx,yyy]:** print true as the string given as `xxx` and false as the string
        given as `yyy`,
    -   **c[tcolor,fcolor]:** color a true element with `tcolor` and a false element
        with `fcolor`. Each of the colors may be specified in the same manner as
        colors for strings described above.

    For example, the directive &rsquo;`b[Yeppers,Nope]c[green.pink,red.pink]`&rsquo; would
    render a true boolean as &rsquo;`Yeppers`&rsquo; colored green on pink and render a false
    boolean as &rsquo;`Nope`&rsquo; colored red on pink. See [Yeppers](https://www.youtube.com/watch?v=oLdFFD8II8U) for additional information.

5.  NilClass

    By default, `nil` elements are rendered as blank cells, but you can make them
    visible with the following, and in that case, all the formatting instructions
    valid for strings are also available:

    -   **n[niltext]:** render a `nil` item with the given niltext.

    For example, you might want to use `'n[-]Cc[purple]'` to make nils visible as a
    centered purple hyphen.


<a id="org947e8a4"></a>

### Footers Methods

You can call the `footer` and `gfooter` methods on `Formatter` objects to add
footers and group footers. Their signatures are:

-   **`footer(label, *sum_cols, **agg_cols)`:** where `label` is a label to be
    placed in the first cell of the footer (unless that column is named as one
    of the `sum_cols` or `agg_cols`, in which case the label is ignored),
    `*sum_cols` are zero or more symbols for columns to be summed, and
    `**agg_cols` is zero or more hash-like parameters with a column symbol as a
    key and a symbol for an aggregate method as the value. This causes a
    table-wide header to be added at the bottom of the table applying the
    `:sum` aggregate to the `sum_cols` and the named aggregate method to the
    `agg_cols`. A table can have any number of footers attached, and they will
    appear at the bottom of the output table in the order they are given.

-   **`gfooter(label, *sum_cols, **agg_cols)`:** where the parameters have the same
    meaning as for the `footer` method, but result in a footer for each group
    in the table rather than the table as a whole. These will appear in the
    output table just below each group.

There are also a number of convenience methods for adding common footers:

-   **`sum_footer(*cols)`:** Add a footer summing the given columns with the label
    &rsquo;Total&rsquo;.
-   **`sum_gfooter(*cols)`:** Add a group footer summing the given columns with the
    label &rsquo;Group Total&rsquo;.
-   **`avg_footer(*cols)`:** Add a footer averaging the given columns with the label
    &rsquo;Average&rsquo;.
-   **`avg_gfooter(*cols)`:** Add a group footer averaging the given columns with the label
    &rsquo;Group Average&rsquo;.
-   **`min_footer(*cols)`:** Add a footer showing the minimum for the given columns
    with the label &rsquo;Minimum&rsquo;.
-   **`min_gfooter(*cols)`:** Add a group footer showing the minumum for the given
    columns with the label &rsquo;Group Minimum&rsquo;.
-   **`max_footer(*cols)`:** Add a footer showing the maximum for the given columns
    with the label &rsquo;Maximum&rsquo;.
-   **`max_gfooter(*cols)`:** Add a group footer showing the maximum for the given
    columns with the label &rsquo;Group Maximum&rsquo;.


<a id="orgcef241a"></a>

### Formatting Methods

You can call methods on  `Formatter` objects to specify formatting directives
for specific columns or types.  There are two methods for doing so, `format_for`
and `format`.

1.  Instantiating a Formatter

    There are several ways to invoke the formatting methods on a table. First, you
    can instantiate a `XXXFormatter` object and feed it a table as a parameter.
    There is a Formatter subclass for each target output medium, for example,
    `AoaFormatter` will produce a ruby array of arrays. You can then call the
    `output` method on the `XXXFormatter`.

        FatTable::AoaFormatter.new(tab_a).output

        | Id | Name  | Age | Address    | Salary |  Join Date |
        |----|-------|-----|------------|--------|------------|
        |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |
        |  3 | Teddy |  23 | Norway     |  20000 | 2007-12-13 |
        |  4 | Mark  |  25 | Rich-Mond  |  65000 | 2007-12-13 |
        |  5 | David |  27 | Texas      |  85000 | 2007-12-13 |
        |  2 | Allen |  25 | Texas      |        | 2005-07-13 |
        |  8 | Paul  |  24 | Houston    |  20000 | 2005-07-13 |
        |  9 | James |  44 | Norway     |   5000 | 2005-07-13 |
        | 10 | James |  45 | Texas      |   5000 |            |

    The `XXXFormatter.new` method yields the new instance to any block given, and
    you can call methods on it to affect the formatting of the output:

        FatTable::AoaFormatter.new(tab_a) do |f|
          f.format(numeric: '0.0,R', id: '3.0C')
        end.output

        |  Id | Name  | Age | Address    | Salary |  Join Date |
        |-----|-------|-----|------------|--------|------------|
        | 001 | Paul  |  32 | California | 20,000 | 2001-07-13 |
        | 003 | Teddy |  23 | Norway     | 20,000 | 2007-12-13 |
        | 004 | Mark  |  25 | Rich-Mond  | 65,000 | 2007-12-13 |
        | 005 | David |  27 | Texas      | 85,000 | 2007-12-13 |
        | 002 | Allen |  25 | Texas      |        | 2005-07-13 |
        | 008 | Paul  |  24 | Houston    | 20,000 | 2005-07-13 |
        | 009 | James |  44 | Norway     |  5,000 | 2005-07-13 |
        | 010 | James |  45 | Texas      |  5,000 |            |

2.  `FatTable` module-level method calls

    The `FatTable` module provides a set of methods of the form `to_aoa`, `to_text`,
    etc., to access a `Formatter` without having to create an instance yourself.
    Without a block, they apply the default formatting to the table and call the
    `.output` method automatically:

        FatTable.to_aoa(tab_a)

        | Id | Name  | Age | Address    | Salary |  Join Date |
        |----|-------|-----|------------|--------|------------|
        |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |
        |  3 | Teddy |  23 | Norway     |  20000 | 2007-12-13 |
        |  4 | Mark  |  25 | Rich-Mond  |  65000 | 2007-12-13 |
        |  5 | David |  27 | Texas      |  85000 | 2007-12-13 |
        |  2 | Allen |  25 | Texas      |        | 2005-07-13 |
        |  8 | Paul  |  24 | Houston    |  20000 | 2005-07-13 |
        |  9 | James |  44 | Norway     |   5000 | 2005-07-13 |
        | 10 | James |  45 | Texas      |   5000 |            |

    With a block, these methods yield a `Formatter` instance on which you can call
    formatting and footer methods. The `.output` method is called on the `Formatter`
    automatically after the block:

        FatTable.to_aoa(tab_a) do |f|
          f.format(numeric: '0.0,R', id: '3.0C')
        end

        |  Id | Name  | Age | Address    | Salary |  Join Date |
        |-----|-------|-----|------------|--------|------------|
        | 001 | Paul  |  32 | California | 20,000 | 2001-07-13 |
        | 003 | Teddy |  23 | Norway     | 20,000 | 2007-12-13 |
        | 004 | Mark  |  25 | Rich-Mond  | 65,000 | 2007-12-13 |
        | 005 | David |  27 | Texas      | 85,000 | 2007-12-13 |
        | 002 | Allen |  25 | Texas      |        | 2005-07-13 |
        | 008 | Paul  |  24 | Houston    | 20,000 | 2005-07-13 |
        | 009 | James |  44 | Norway     |  5,000 | 2005-07-13 |
        | 010 | James |  45 | Texas      |  5,000 |            |

3.  Calling methods on Table objects

    Finally, you can call methods such as `to_aoa`, `to_text`, etc., directly on a
    Table:

        tab_a.to_aoa

        | Id | Name  | Age | Address    | Salary |  Join Date |
        |----|-------|-----|------------|--------|------------|
        |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |
        |  3 | Teddy |  23 | Norway     |  20000 | 2007-12-13 |
        |  4 | Mark  |  25 | Rich-Mond  |  65000 | 2007-12-13 |
        |  5 | David |  27 | Texas      |  85000 | 2007-12-13 |
        |  2 | Allen |  25 | Texas      |        | 2005-07-13 |
        |  8 | Paul  |  24 | Houston    |  20000 | 2005-07-13 |
        |  9 | James |  44 | Norway     |   5000 | 2005-07-13 |
        | 10 | James |  45 | Texas      |   5000 |            |

    And you can supply a block to them as well to specify formatting or footers:

        tab_a.to_aoa do |f|
          f.format(numeric: '0.0,R', id: '3.0C')
          f.sum_footer(:salary, :age)
        end

        |    Id | Name  | Age | Address    |  Salary |  Join Date |
        |-------|-------|-----|------------|---------|------------|
        |   001 | Paul  |  32 | California |  20,000 | 2001-07-13 |
        |   003 | Teddy |  23 | Norway     |  20,000 | 2007-12-13 |
        |   004 | Mark  |  25 | Rich-Mond  |  65,000 | 2007-12-13 |
        |   005 | David |  27 | Texas      |  85,000 | 2007-12-13 |
        |   002 | Allen |  25 | Texas      |         | 2005-07-13 |
        |   008 | Paul  |  24 | Houston    |  20,000 | 2005-07-13 |
        |   009 | James |  44 | Norway     |   5,000 | 2005-07-13 |
        |   010 | James |  45 | Texas      |   5,000 |            |
        |-------|-------|-----|------------|---------|------------|
        | Total |       | 245 |            | 220,000 |            |


<a id="org7b25866"></a>

### The `format` and `format_for` methods

Formatters take only two kinds of methods, those that attach footers to a
table, which are discussed in the next section, and those that specify
formatting for table cells, which are the subject of this section.

To set formatting directives for all locations in a table at once, use the
`format` method; to set formatting directives for a particular location in the
table, use the `format_for` method, giving the location as the first parameter.

Other than that first parameter, the two methods take the same types of
parameters. The remaining parameters are hash-like parameters that use either a
column name or a type as the key and a string with the formatting directives to
apply as the value. The following example says to set the formatting for all
locations in the table and to format all numeric fields as strings that are
rounded to whole numbers (the &rsquo;0.0&rsquo; part), that are right-aligned (the &rsquo;R&rsquo;
part), and have grouping commas inserted (the &rsquo;,&rsquo; part). But the `:id` column is
numeric, and the second parameter overrides the formatting for numerics in
general and calls for the `:id` column to be padded to three digits with zeros
on the left (the &rsquo;3.0&rsquo; part) and to be centered (the &rsquo;C&rsquo; part).

    tab_a.to_aoa do |f|
      f.format(numeric: '0.0,R', id: '3.0C')
    end

    |  Id | Name  | Age | Address    | Salary |  Join Date |
    |-----|-------|-----|------------|--------|------------|
    | 001 | Paul  |  32 | California | 20,000 | 2001-07-13 |
    | 003 | Teddy |  23 | Norway     | 20,000 | 2007-12-13 |
    | 004 | Mark  |  25 | Rich-Mond  | 65,000 | 2007-12-13 |
    | 005 | David |  27 | Texas      | 85,000 | 2007-12-13 |
    | 002 | Allen |  25 | Texas      |        | 2005-07-13 |
    | 008 | Paul  |  24 | Houston    | 20,000 | 2005-07-13 |
    | 009 | James |  44 | Norway     |  5,000 | 2005-07-13 |
    | 010 | James |  45 | Texas      |  5,000 |            |

The `numeric:` directive affected the `:age` and `:salary` columns and the `id:`
directive affected only the `:id` column. All the other cells in the table had
the default formatting applied.

1.  Location priority

    Formatting for any given cell depends on its location in the table. The
    `format_for` method takes a location to which its formatting directive are
    restricted as the first argument. It can be one of the following:

    -   **`:header`:** directive apply only to the header row, that is the first row, of
        the output table,

    -   **`:footer`:** directives apply to all the footer rows of the output table,
        regardless of how many there are,

    -   **`gfooter`:** directives apply to all group footer rows of the output tables,
        regardless of how many there are,

    -   **`:body`:** directives apply to all rows in the body of the table unless the
        row is the first row in the table or in a group and separate directives for
        those have been given, in which case those directives apply,

    -   **`:gfirst`:** directives apply to the first row in each group in the body of
        the table, unless the row is also the first row in the table as a whole, in
        which case the `:bfirst` directives apply,

    -   **`:bfirst`:** directives apply to the first row in the body of the table.

    If you give directives for `:body`, they are copied to `:bfirst` and `:gfirst`
    as well and can be overridden by directives for those locations.

    Directives given to the `format` method apply the directives to all locations in
    the table, but they can be overridden by more specific directives given in a
    `format_for` directive.

2.  Type and Column priority

    A directive based on type applies to all columns having that type unless
    overridden by a directive specific to a named column; a directive based on a
    column name applies only to cells in that column.

    However, there is a twist.  Since the end result of formatting is to convert all
    columns to strings, the formatting directives for the `:string` type applies to
    all columns.  Likewise, since all columns may contain nils, the `nil:` type
    applies to nils in all columns regardless of the column&rsquo;s type.

        require 'fat_table'
          tab_a.to_text do |f|
            f.format(string: 'R', id: '3.0C', salary: 'n[N/A]')
          end

        +=====+=======+=====+============+========+============+
        |  Id |  Name | Age |    Address | Salary |  Join Date |
        +-----|-------|-----|------------|--------|------------+
        | 001 |  Paul |  32 | California |  20000 | 2001-07-13 |
        | 003 | Teddy |  23 |     Norway |  20000 | 2007-12-13 |
        | 004 |  Mark |  25 |  Rich-Mond |  65000 | 2007-12-13 |
        | 005 | David |  27 |      Texas |  85000 | 2007-12-13 |
        | 002 | Allen |  25 |      Texas |    N/A | 2005-07-13 |
        | 008 |  Paul |  24 |    Houston |  20000 | 2005-07-13 |
        | 009 | James |  44 |     Norway |   5000 | 2005-07-13 |
        | 010 | James |  45 |      Texas |   5000 |            |
        +=====+=======+=====+============+========+============+

    The `string: 'R'` directive causes all the cells to be right-aligned except
    `:id` which specifies centering for the `:id` column only. The `n[N/A]`
    directive for specifies how nil are displayed in the numeric column, `:salary`,
    but not for other nils, such as in the last row of the `:join_date` column.


<a id="org62e325b"></a>

# Development

After checking out the repo, run \`bin/setup\` to install dependencies. Then, run
\`rake spec\` to run the tests. You can also run \`bin/console\` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run \`bundle exec rake install\`. To
release a new version, update the version number in \`version.rb\`, and then run
\`bundle exec rake release\`, which will create a git tag for the version, push
git commits and tags, and push the \`.gem\` file to
[rubygems.org](<https://rubygems.org>).


<a id="orgf51a2c9"></a>

# Contributing

Bug reports and pull requests are welcome on GitHub at
<https://github.com/ddoherty03/fat_table>.
