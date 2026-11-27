- [Version 1.1.1 <span class="timestamp-wrapper"><span class="timestamp">[2026-11-27 Fri]</span></span>](#org6a38a16)
- [Version 1.1.0 <span class="timestamp-wrapper"><span class="timestamp">[2026-11-23 Mon]</span></span>](#org51297db)
- [Version 1.0.1 <span class="timestamp-wrapper"><span class="timestamp">[2026-11-21 Sat]</span></span>](#org07e1332)
- [Version 1.0.0 <span class="timestamp-wrapper"><span class="timestamp">[2025-12-28 Sun]</span></span>](#orgde7ad59)
- [Version 0.9.9 <span class="timestamp-wrapper"><span class="timestamp">[2025-03-19 Wed]</span></span>](#org23684a4)
- [Version 0.9.8 <span class="timestamp-wrapper"><span class="timestamp">[2024-12-31 Tue]</span></span>](#org1308011)
- [Version 0.9.7 <span class="timestamp-wrapper"><span class="timestamp">[2024-12-26 Thu]</span></span>](#orgc5ff6d7)
- [Version 0.9.5 <span class="timestamp-wrapper"><span class="timestamp">[2023-11-07 Tue]</span></span>](#orgc20f7b4)
- [Version 0.9.3 <span class="timestamp-wrapper"><span class="timestamp">[2023-05-24 Wed]</span></span>](#org8bd5491)
- [Version 0.9.2 <span class="timestamp-wrapper"><span class="timestamp">[2023-05-22 Mon]</span></span>](#org259e6ba)
- [Version 0.9.1 <span class="timestamp-wrapper"><span class="timestamp">[2023-05-22 Mon]</span></span>](#org85a9031)
- [Version 0.9.0 <span class="timestamp-wrapper"><span class="timestamp">[2023-05-22 Mon]</span></span>](#orgbae2528)
- [Version 0.8.0 <span class="timestamp-wrapper"><span class="timestamp">[2023-04-20 Thu]</span></span>](#org80b935c)
- [Version 0.7.0 <span class="timestamp-wrapper"><span class="timestamp">[2023-04-02 Sun]</span></span>](#orgf31a238)
- [Version 0.6.6 <span class="timestamp-wrapper"><span class="timestamp">[2023-01-09 Mon]</span></span>](#org5e104a2)
- [Version 0.6.3 <span class="timestamp-wrapper"><span class="timestamp">[2022-06-04 Sat]</span></span>](#org1a479c2)
- [Version 0.6.2 <span class="timestamp-wrapper"><span class="timestamp">[2022-05-24 Tue]</span></span>](#org85d2aaa)
- [Version 0.6.1 <span class="timestamp-wrapper"><span class="timestamp">[2022-03-26 Sat]</span></span>](#orgc980888)
- [Version 0.6.0 <span class="timestamp-wrapper"><span class="timestamp">[2022-03-26 Sat]</span></span>](#org1ad3032)
- [Version 0.5.5 <span class="timestamp-wrapper"><span class="timestamp">[2022-03-25 Fri]</span></span>](#orgbacb0ad)
- [Version 0.5.4 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-27 Thu]</span></span>](#org376df0c)
- [Version 0.5.3 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-24 Mon]</span></span>](#org6bab4e7)
- [Version 0.5.2 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-22 Sat]</span></span>](#org779aee6)
- [Version 0.5.1 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-21 Fri]</span></span>](#org29c7473)
- [Version 0.4.2 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-06 Thu]</span></span>](#org520acaa)
- [Version 0.4.0 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-02 Sun]</span></span>](#orgf1930f0)
- [Version 0.3.4 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-01 Sat]</span></span>](#orgefe8a18)
- [Version 0.3.3 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-01 Sat]</span></span>](#org1f68e8b)
- [Version 0.3.1 <span class="timestamp-wrapper"><span class="timestamp">[2020-12-13 Sun]</span></span>](#orgd990727)
- [Version 0.3.0 <span class="timestamp-wrapper"><span class="timestamp">[2020-06-10 Wed]</span></span>](#orgeab0105)
- [Version 0.2.11 <span class="timestamp-wrapper"><span class="timestamp">[2019-12-29 Sun]</span></span>](#orge5bcc42)
- [Version 0.2.9 <span class="timestamp-wrapper"><span class="timestamp">[2019-04-04 Thu]</span></span>](#org4b9f276)
- [Version 0.2.8 <span class="timestamp-wrapper"><span class="timestamp">[2018-08-28 Tue]</span></span>](#orgccd4e3c)
- [Version 0.2.7 <span class="timestamp-wrapper"><span class="timestamp">[2017-12-29 Fri]</span></span>](#orgfa6b25c)
- [Version 0.2.6 <span class="timestamp-wrapper"><span class="timestamp">[2017-10-27 Fri]</span></span>](#orge932853)
- [Version 0.2.4 <span class="timestamp-wrapper"><span class="timestamp">[2017-05-23 Tue]</span></span>](#org5f1aa2f)
- [Version 0.2.3 <span class="timestamp-wrapper"><span class="timestamp">[2017-05-08 Mon]</span></span>](#org581370f)
- [Version 0.2.2 <span class="timestamp-wrapper"><span class="timestamp">[2017-05-08 Mon]</span></span>](#org19d5cf6)


<a id="org6a38a16"></a>

# Version 1.1.1 <span class="timestamp-wrapper"><span class="timestamp">[2026-11-27 Fri]</span></span>

-   Faster report formatting, especially for long tables.
-   Faster natural and symbol-based equality joins.
-   Faster sorting and grouped `select` and `where` operations.
-   Faster row insertion, especially for wide tables, and more efficient handling of column values.
-   Existing ordering, grouping, and numeric precision are preserved.


<a id="org51297db"></a>

# Version 1.1.0 <span class="timestamp-wrapper"><span class="timestamp">[2026-11-23 Mon]</span></span>

-   `order_by` and `order_with` now implement stable sorting.


<a id="org07e1332"></a>

# Version 1.0.1 <span class="timestamp-wrapper"><span class="timestamp">[2026-11-21 Sat]</span></span>

-   Eliminate loading of debug which interferes with Windows use.


<a id="orgde7ad59"></a>

# Version 1.0.0 <span class="timestamp-wrapper"><span class="timestamp">[2025-12-28 Sun]</span></span>

-   Bug fixes.
-   Numeric default post-digits changed from 0 to 4 so BigDecimal can be distinguished from Integers.
-   README more readable with above fix.
-   Documentation improvements.
-   CHANGELOG added.


<a id="org23684a4"></a>

# Version 0.9.9 <span class="timestamp-wrapper"><span class="timestamp">[2025-03-19 Wed]</span></span>

-   bug fixes

-   No notable changes.


<a id="org1308011"></a>

# Version 0.9.8 <span class="timestamp-wrapper"><span class="timestamp">[2024-12-31 Tue]</span></span>

-   bug fixes

-   No notable changes.


<a id="orgc5ff6d7"></a>

# Version 0.9.7 <span class="timestamp-wrapper"><span class="timestamp">[2024-12-26 Thu]</span></span>

-   bug fixes

-   No notable changes


<a id="orgc20f7b4"></a>

# Version 0.9.5 <span class="timestamp-wrapper"><span class="timestamp">[2023-11-07 Tue]</span></span>

-   Raise FatTable::NoTable exception when no table can be formed from the input.
-   Ingore org rows with the wrong number of columns.


<a id="org8bd5491"></a>

# Version 0.9.3 <span class="timestamp-wrapper"><span class="timestamp">[2023-05-24 Wed]</span></span>

-   Bug fixes


<a id="org259e6ba"></a>

# Version 0.9.2 <span class="timestamp-wrapper"><span class="timestamp">[2023-05-22 Mon]</span></span>

-   Bug fixes


<a id="org85a9031"></a>

# Version 0.9.1 <span class="timestamp-wrapper"><span class="timestamp">[2023-05-22 Mon]</span></span>

-   Bug fixes


<a id="orgbae2528"></a>

# Version 0.9.0 <span class="timestamp-wrapper"><span class="timestamp">[2023-05-22 Mon]</span></span>

-   Bug fixes


<a id="org80b935c"></a>

# Version 0.8.0 <span class="timestamp-wrapper"><span class="timestamp">[2023-04-20 Thu]</span></span>

-   Changed the API to allow explicit column typing and tolerance designation with keyword args such as `head1: 'num~'` to make `head1` column be typed as numeric (the `num` part) but tolerant (the `~`)


<a id="orgf31a238"></a>

# Version 0.7.0 <span class="timestamp-wrapper"><span class="timestamp">[2023-04-02 Sun]</span></span>

-   Bug fixes


<a id="org5e104a2"></a>

# Version 0.6.6 <span class="timestamp-wrapper"><span class="timestamp">[2023-01-09 Mon]</span></span>

-   Changed the default number of post-decimal digits to 0 for Numeric,


<a id="org1a479c2"></a>

# Version 0.6.3 <span class="timestamp-wrapper"><span class="timestamp">[2022-06-04 Sat]</span></span>

-   Allow select to set new column to a constant,
-   Allow select string expression to signal literal string with a leading colon, since string constants are now allowed; otherwise eval the string.
-   Added day-of-week to org-formatted dates just like `org-mode`


<a id="org85d2aaa"></a>

# Version 0.6.2 <span class="timestamp-wrapper"><span class="timestamp">[2022-05-24 Tue]</span></span>

-   Bug fixes


<a id="orgc980888"></a>

# Version 0.6.1 <span class="timestamp-wrapper"><span class="timestamp">[2022-03-26 Sat]</span></span>

-   Fixed bug in dynamic labels in footers,


<a id="org1ad3032"></a>

# Version 0.6.0 <span class="timestamp-wrapper"><span class="timestamp">[2022-03-26 Sat]</span></span>

-   Added dynamic labels in footers,


<a id="orgbacb0ad"></a>

# Version 0.5.5 <span class="timestamp-wrapper"><span class="timestamp">[2022-03-25 Fri]</span></span>

-   Better handling of aggregates for all-nil columns


<a id="org376df0c"></a>

# Version 0.5.4 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-27 Thu]</span></span>

-   Aggregate function filter out all type-incompatible elements, not just nils, since tolerant columns may have such elements,
-   Make header-based formatting a higher priority than type-based formatting,


<a id="org6bab4e7"></a>

# Version 0.5.3 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-24 Mon]</span></span>

-   Added support for "tolerant" column types that allow non-coercable strings in non-String columns,


<a id="org779aee6"></a>

# Version 0.5.2 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-22 Sat]</span></span>

-   documentation only


<a id="org29c7473"></a>

# Version 0.5.1 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-21 Fri]</span></span>

-   changed `rng` column aggregate to `range` and return `Range(min, max)`
-   Added new methods for forming table footers based on aggregates,
-   Allow lambdas as group aggregate functions,
-   Improved handling of nils in aggregate and `order_by`,
-   Added an `order_with` method for ordering by expression,
-   Bug fixes and performance improvements,
-   Added special symbol `:omni` in `select` as short-hand for all columns,


<a id="org520acaa"></a>

# Version 0.4.2 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-06 Thu]</span></span>

-   bug fixes only


<a id="orgf1930f0"></a>

# Version 0.4.0 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-02 Sun]</span></span>

-   bug fixes only


<a id="orgefe8a18"></a>

# Version 0.3.4 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-01 Sat]</span></span>

-   minor bug fix only


<a id="org1f68e8b"></a>

# Version 0.3.3 <span class="timestamp-wrapper"><span class="timestamp">[2022-01-01 Sat]</span></span>

-   Added date format 'Tue, 01 Nov 2016' to be parsed as a Date.


<a id="orgd990727"></a>

# Version 0.3.1 <span class="timestamp-wrapper"><span class="timestamp">[2020-12-13 Sun]</span></span>

-   documentation only


<a id="orgeab0105"></a>

# Version 0.3.0 <span class="timestamp-wrapper"><span class="timestamp">[2020-06-10 Wed]</span></span>

-   gem dependency changes only


<a id="orge5bcc42"></a>

# Version 0.2.11 <span class="timestamp-wrapper"><span class="timestamp">[2019-12-29 Sun]</span></span>

-   bug fixes only


<a id="org4b9f276"></a>

# Version 0.2.9 <span class="timestamp-wrapper"><span class="timestamp">[2019-04-04 Thu]</span></span>

-   documentation fixes only


<a id="orgccd4e3c"></a>

# Version 0.2.8 <span class="timestamp-wrapper"><span class="timestamp">[2018-08-28 Tue]</span></span>

-   No notable changes


<a id="orgfa6b25c"></a>

# Version 0.2.7 <span class="timestamp-wrapper"><span class="timestamp">[2017-12-29 Fri]</span></span>

-   Minor bug fixes and performance improvements


<a id="orge932853"></a>

# Version 0.2.6 <span class="timestamp-wrapper"><span class="timestamp">[2017-10-27 Fri]</span></span>

-   Added recognition of American-style dates
-   Allows + or negative signs before numbers
-   Added `ivars` that can be set in `before_hook` and `after_hook`
-   Allowed American-order date 'mm-dd-yyyy' to be parsed


<a id="org5f1aa2f"></a>

# Version 0.2.4 <span class="timestamp-wrapper"><span class="timestamp">[2017-05-23 Tue]</span></span>

-   Added instance variables to ft\_console


<a id="org581370f"></a>

# Version 0.2.3 <span class="timestamp-wrapper"><span class="timestamp">[2017-05-08 Mon]</span></span>

-   No notable changes


<a id="org19d5cf6"></a>

# Version 0.2.2 <span class="timestamp-wrapper"><span class="timestamp">[2017-05-08 Mon]</span></span>

-   Initial release
