A Test Harness for the QT3 Test Suite in Pure XQuery
====================================================

This is an (incomplete) attempt at building a test harness for the W3C QT3
test suite in pure XQuery.

In addition to XQuery 3.0, the XQuery processor used to run the test suite
currently needs to support the following features:

  * XQuery maps as proposed by Michael Kay
  * a way of evaluating XQuery strings as queries at runtime
  * the EXPath file module.

All code is available under the *BSD license*.

eXist edition
-------------

- Clone this repository, upload to `/db/apps/fots-basex`
- Clone the QT3 test suite:`git clone https://github.com/LeoWoerteler/QT3TS.git`
- Update `fots.xq` with path to QT3TS cloned directory: https://github.com/joewiz/fots-basex/blob/exist/fots.xq#L12 and with where results should be saved: https://github.com/joewiz/fots-basex/blob/exist/fots.xq#L78
- Call <http://localhost:8080/exist/apps/fots-basex/fots.xq>
