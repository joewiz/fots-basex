(:~
 : XQuery driver for the QT3 Test Suite.
 :
 : @author BaseX Team 2005-11, BSD License
 : @author Leo Wörteler
 : @version 0.1
 :)
module namespace fots = "http://www.w3.org/2010/09/qt-fots-catalog";

declare namespace map = "http://www.w3.org/2005/xpath-functions/map";

import module namespace env = "http://www.w3.org/2010/09/qt-fots-catalog/environment"
    at "fots-environment.xqm";
import module namespace check = "http://www.w3.org/2010/09/qt-fots-catalog/check"
  at 'fots-check.xqm';

(:~
 : Loops throgh the test set and evaluates all test cases.
 : @param $path    - path to the FOTS catalog file
 : @return an element containing all failed tests
 :)
declare function fots:run(
  $eval as function(xs:string) as item()*,
  $path as xs:string
) as element(fots:failures) {
  fots:run($eval, $path, function($name, $val) { true() }, '', '')
};

(:~
 : Loops throgh the test set and evaluates all test cases.
 : @param $path    - path to the FOTS catalog file
 : @param $exclude - predicate function for excluding dependencies
 : @return an element containing all failed tests
 :)
declare function fots:run(
  $eval as function(xs:string) as item()*,
  $path as xs:string,
  $exclude as function(xs:string, xs:string) as xs:boolean
) as element(fots:failures) {
  fots:run($eval, $path, $exclude, '', '')
};

(:~
 : Loops throgh the test set and evaluates all test cases.
 : @param $path    - path to the FOTS catalog file
 : @param $exclude - predicate function for excluding dependencies
 : @param $catalog - name f the catalog to use (empty string means all)
 : @return an element containing all failed tests
 :)
declare function fots:run(
  $eval as function(xs:string) as item()*,
  $path as xs:string,
  $exclude as function(xs:string, xs:string) as xs:boolean,
  $catalog as xs:string
) as element(fots:failures) {
  fots:run($eval, $path, $exclude, $catalog, '')
};

(:~
 : Loops throgh the test set and evaluates all test cases.
 : @param $path    - path to the FOTS catalog file
 : @param $exclude - predicate function for excluding dependencies
 : @param $catalog - name of the catalog to use (empty string means all)
 : @param $prefix  - prefix of test-cases to use (empty string means all)
 : @return an element containing all failed tests
 :)
declare function fots:run(
  $eval as function(xs:string) as item()*,
  $path as xs:string,
  $exclude as function(xs:string, xs:string) as xs:boolean,
  $catalog as xs:string,
  $prefix as xs:string
) as element(fots:failures) {
  <failures xmlns="http://www.w3.org/2010/09/qt-fots-catalog">{
    let $doc := doc($path || '/catalog.xml'),
        $env := $doc//fots:environment

    for $set in $doc//fots:test-set[starts-with(@name, $catalog)]
    let $href := $set/@file,
        $doc-uri := $path || "/" || $href,
        $doc := doc($doc-uri)

    for $case in $doc//fots:test-case[starts-with(@name, $prefix)]
    let $env := $env | $doc//fots:environment,
        $map := env:environment($case/fots:environment, $env)
    where not(map:contains($map, 'collation'))
        and fold-left(
            $case/fots:dependency,
            true(),
            function($rest, $dep) {
                $rest and not($exclude($dep/@type, $dep/@value))
            }
        )
    return
        let $debug := util:log("info", ("doc-uri=" || $doc-uri))
        let $debug := util:log("info", ("map=" || serialize($map, map { "method": "adaptive" })))
        return
        
        fots:test($eval, $case, $map, $path, replace($href, '/.*','/'))
            
  }</failures>
};

(:~
 : Runs a single test.
 :
 : @param $case - test-case element
 : @param $map  - environment map
 : @param $path - path to the test suite
 : @param $sub  - relative path to the test group
 : @return <code>()</code> on success, the failed
 :   test-case element with additional information otherwise
 :)
declare function fots:test(
  $eval as function(xs:string) as item()*,
  $case as element(fots:test-case),
  $map as map(*),
  $path as xs:string,
  $sub as xs:string
) as element(fots:test-case)? {
  let $query  := $case/fots:test/text(),
      $prolog := env:prolog($map, $path, $sub),
      $query  := string-join(($prolog, $query), '&#xa;'),
      $result := 
        try {
        
          let $debug := util:log("info", ("name=" || $case/@name || " query=" || normalize-space($query)))
        
          let $res := $eval($query)
          return check:result($eval, $res, $case/fots:result/*)
        } catch * {
          check:error($err:code, $err:description, $case/fots:result/*)
        }
  return if(empty($result)) then ()
    else fots:wrong($case, $result, $query)
};

(: gives feedback on an erroneous query :)
declare function fots:wrong(
  $test as element(fots:test-case),
  $result as item()*,
  $query as xs:string
) as element(fots:test-case)? {
  
  (: TODO (AR) below is a pale hack, e.g. does not remove descendant::comment() :)
  element { $test/node-name() } {
    $test/@*,
    $test/child::node()[not(local-name(.) eq "description")],
    <wrong>
        <query>{ $query }</query>
        {$result}
    </wrong> 
  }
  
  (: TODO (AR) original below :)
  
  (:
  copy $c := $test
  modify (
    insert node
      <wrong>
        <query>{ $query }</query>
        {$result}
      </wrong> into $c,
      delete node $c/description,
      delete nodes $c/descendant::comment()
    )
  return $c
  :)
};
