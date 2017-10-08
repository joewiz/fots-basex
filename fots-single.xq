(:~
 : Start script of the XQuery driver for the QT3 Test Suite.
 :
 : @author BaseX Team 2005-11, BSD License
 : @author Leo Wörteler
 : @version 0.1
 :)
import module namespace fots = "http://www.w3.org/2010/09/qt-fots-catalog"
  at 'fots.xqm';
import module namespace env = "http://www.w3.org/2010/09/qt-fots-catalog/environment"
    at "fots-environment.xqm";
import module namespace check = "http://www.w3.org/2010/09/qt-fots-catalog/check"
  at 'fots-check.xqm';

declare default element namespace "http://www.w3.org/2010/09/qt-fots-catalog";

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
  util:eval(replace($query, '&#xD;', '&amp;#xD;'))
};

let $eval := local:eval#1,
    $case := $path,
    $exclude := local:exclude#2,
    $catalog := "method-xml",
    $prefix := "K2-Serialization-24"

let $doc := doc($path || '/catalog.xml'),
    $env := $doc//environment

for $set in $doc//test-set[starts-with(@name, $catalog)]
let $href := $set/@file,
    $doc-uri := $path || "/" || $href,
    $doc := doc($doc-uri)

for $case in $doc//test-case[starts-with(@name, $prefix)]
let $env := $env | $doc//environment,
    $map := env:environment($case/environment, $env)
where not(map:contains($map, 'collation'))
    and fold-left(
        $case/dependency,
        true(),
        function($rest, $dep) {
            $rest and not($exclude($dep/@type, $dep/@value))
        }
    )
return
    (
(:        check:result($eval, $eval($case/test/text()), $case/result/*):)
    fots:test($eval, $case, $map, $path, replace($href, '/.*','/'))
(:($eval, $case, $map, $path, replace($href, '/.*','/')):)
    )