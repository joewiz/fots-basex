(:~
 : Start script of the XQuery driver for the QT3 Test Suite.
 :
 : @author BaseX Team 2005-11, BSD License
 : @author Leo Wörteler
 : @version 0.1
 :)
import module namespace fots = "http://www.w3.org/2010/09/qt-fots-catalog"
  at 'fots.xqm';

(:~ Path to the test suite files. :)
declare variable $path as xs:string := "file:/Users/joe/workspace/QT3TS";

(:~
 : Predicate function for excluding tests with unsupported dependencies.
 : @param $dep   - dependency name
 : @param $value - dependency string value
 : @return <code>true()</code> if the test should be skipped,
 :   <code>false()</code> otherwise
 :)
declare function local:exclude(
  $dep as xs:string,
  $val as xs:string
) as xs:boolean {
  let $map := map{
      'feature': 'namespace-axis',
      'xml-version': '1.1'
    }
  return $map($dep) = $val
    (:
    or $dep eq 'format-integer-sequence'
      and (
        try {
          empty(util:eval(concat('format-integer(1, "', $val, '")')))
        } catch * {
          true()
        }
      )
    :)
};

(:~
 : Evaluation function (implementation-specific).
 : @param $query - query to be executed
 : @return evaluation result
 :)
declare function local:eval(
  $query as xs:string
) as item()* {
  util:eval($query)
};

declare function local:clean($nodes) {
    for $node in $nodes
    return
        typeswitch ($node)
            case text() return replace($node, "&#x8;", "&amp;#x8;")
            case element() return element { node-name($node) } { $node/@*, local:clean($node/node()) }
            default return $node
};

let $login := xmldb:login('/db', 'admin', '')
let $start-time := util:system-time()
let $log := util:log("info", "started qt3 tests at " || $start-time)
let $failures := 
fots:run(
  local:eval#1,
  $path,
  local:exclude#2
)
let $end-time := util:system-time()
let $time-to-completion := $end-time - $start-time
let $log := util:log("info", "finished qt3 tests at " || $end-time)
let $log := util:log("info", "qt3 tests took " || $time-to-completion)
return
    <results>
        (: $failures, :)
        try { file:serialize($failures, "/Users/joe/Downloads/fots-results/fots-" || (current-date() => adjust-date-to-timezone(())) || ".xml", ()) } catch * { <error>couldn't store fots results in db</error> },
        <start-time>{$start-time}</start-time>
        <end-time>{$end-time}</end-time>
        <time-to-completion>{$end-time - $start-time}</time-to-completion>
    </results>