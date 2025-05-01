/// Default CSS for HTML elements. Based on the default CSS from Firefox.
const htmlCss = '''
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* blocks */

article,
aside,
details,
div,
dt,
figcaption,
footer,
form,
header,
hgroup,
html,
main,
nav,
search,
section,
summary { 
  display: block;
}

body {
  display: block;
  margin: 8px;
}

p,
dl {
    display: block;
    margin-block-start: 1em;
    margin-block-end: 1em;
}

dd {
    display: block;
    margin-inline-start: 40px;
}

blockquote,
figure {
    display: block;
    margin-block: 1em;
    margin-inline: 40px;
}

address {
    display: block;
    font-style: italic;
}

center {
    display: block;
    text-align: -moz-center;
}

h1 {
    display: block;
    font-size: 2em;
    font-weight: bold;
    margin-block: .67em;
}

h2 {
    display: block;
    font-size: 1.5em;
    font-weight: bold;
    margin-block: .83em;
}

h3 {
    display: block;
    font-size: 1.17em;
    font-weight: bold;
    margin-block: 1em;
}

h4 {
    display: block;
    font-size: 1.00em;
    font-weight: bold;
    margin-block: 1.33em;
}

h5 {
    display: block;
    font-size: 0.83em;
    font-weight: bold;
    margin-block: 1.67em;
}

h6 {
    display: block;
    font-size: 0.67em;
    font-weight: bold;
    margin-block: 2.33em;
}

listing {
    display: block;
    font-family: -moz-fixed;
    font-size: medium;
    white-space: pre;
    margin-block: 1em;
}

xmp,
pre,
plaintext {
    display: block;
    font-family: -moz-fixed;
    white-space: pre;
    margin-block: 1em;
}

q:before {
    content: open-quote;
}

q:after {
    content: close-quote;
}

b,
strong {
    font-weight: bolder;
}

i,
cite,
em,
var,
dfn {
    font-style: italic;
}

tt,
code,
kbd,
samp {
    font-family: -moz-fixed;
}

u,
ins {
    text-decoration: underline;
}

s,
strike,
del {
    text-decoration: line-through;
}

big {
    font-size: larger;
}

small {
    font-size: smaller;
}

sub {
    vertical-align: sub;
    font-size: smaller;
}

sup {
    vertical-align: super;
    font-size: smaller;
}

nobr {
    white-space: nowrap;
}


/* titles */
abbr,
acronym {
    text-decoration: dotted underline;
}

/* lists */

ul,
menu,
dir {
    display: block;
    list-style-type: disc;
    margin-block-start: 1em;
    margin-block-end: 1em;
    padding-left: 40px;
    /*    padding-inline-start: 40px;*/
}


ol {
    display: block;
    list-style-type: decimal;
    margin-block-start: 1em;
    margin-block-end: 1em;
    padding-left: 40px;
    /*    padding-inline-start: 40px;*/
}

li {
    display: list-item;
    text-align: match-parent;
}

/* leafs */

/* <hr> noshade and color attributes are handled completely by
  * HTMLHRElement::MapAttributesIntoRule.
  * https://html.spec.whatwg.org/#the-hr-element-2
  */
hr {
    color: gray;
    border-width: 1px;
    border-style: inset;
    margin-block: 0.5em;
    margin-inline: auto;
    overflow: hidden;

    /* FIXME: This is not really per spec */
    display: block;
}

''';
