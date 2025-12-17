// Swift testcases for matching wildcards.
//
// Copyright 2025 Kirk J Krauss.  This is a Derivative Work based on
// material that is copyright 2018 IBM Corporation and available at
//
//	https://developforperformance.com/MatchingWildcardsInRust.html
//
// Licensed under the Apache License, Version 2.0 (the "License")
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//	https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// This file provides sets of correctness and performance tests, for
// matching wildcards in Swift, along with a main() routine that invokes 
// the testcases and outputs the results.
//
import Foundation
infix operator &&=

// File-scope testcase selection flags.
//
fileprivate let bComparePerformance   = true
fileprivate let bTestWild             = true
fileprivate let bTestTame             = true
fileprivate let bTestEmpty            = true
fileprivate let bTestUtf8             = false
fileprivate let bTestCaseInsensitive  = true

// File-scope variables for low-latency accumulation of performance data.
//
fileprivate nonisolated(unsafe) var iAccumulatedTimeCaseSensitive: UInt64  = 0
fileprivate nonisolated(unsafe) var iAccumulatedTimeCaseInsensitive: UInt64 = 0
	// Can add accumulator variables for more performance comparisons here...

// This flag is set for case-sensitive tests to factor them out of performance
// comparisons involving any case-insensitive routine for matching wildcards.
//
fileprivate nonisolated(unsafe) var bCaseInsensitivityCheck: Bool = false;

// This function compares a tame/wild string pair via each included routine.
func test(strTame: String, strWild: String, bExpectedResult: Bool) -> Bool
{
	var bPassed = true
	var timeStart: UInt64
	var timeFinish: UInt64

	if bComparePerformance && !bCaseInsensitivityCheck
	{
		// Get execution times for our two matching wildcards routines.
		timeStart = DispatchTime.now().uptimeNanoseconds

		if bExpectedResult != FastWildCompare(
		                         strWild: strWild, strTame: strTame)
		{
			bPassed = false
		}
		
		timeFinish = DispatchTime.now().uptimeNanoseconds
		iAccumulatedTimeCaseSensitive += timeFinish - timeStart

		if bTestCaseInsensitive
		{
			timeStart = DispatchTime.now().uptimeNanoseconds

			if bExpectedResult != FastWildCaseCompare(
		                             strWild: strWild, strTame: strTame)
			{
				bPassed = false
			}

			timeFinish = DispatchTime.now().uptimeNanoseconds
			iAccumulatedTimeCaseInsensitive += timeFinish - timeStart
		}

		// Can add more performance comparisons here...
	}
	else if bTestCaseInsensitive
	{
		// Case-insensitive matching:
		if bExpectedResult != FastWildCaseCompare(
		                         strWild: strWild, strTame: strTame)
		{
			bPassed = false
		}
	}
	else
	{
		// Case-sensitive matching:
		if bExpectedResult != FastWildCompare(
		                         strWild: strWild, strTame: strTame)
		{
			bPassed = false
		}
	}	
	
	// Can add tests for more matching wildcards routines here...

	return bPassed
}

// This function implements the &&= operator.
func &&= (lhs: inout Bool, rhs: @autoclosure () -> Bool)
{
    lhs = lhs && rhs()
}

// A set of wildcard comparison tests.
func testwild()
{
	var iReps: Int
	var bAllPassed: Bool = true

	if bComparePerformance
	{
		// Can choose as many repetitions as you might expect in production.
		iReps = 1000000
	}
	else
	{
		iReps = 1
	}

	while iReps > 0
	{
		iReps -= 1

		// Case with first wildcard after total match.
		bAllPassed &&= test(strTame: "Hi",
		   strWild: "Hi*",
		   bExpectedResult: true)

		// Case with mismatch after '*'.
		bAllPassed &&= test(strTame: "abc",
		   strWild: "ab*d",
		   bExpectedResult: false)

		// Cases with repeating character sequences.
		bAllPassed &&= test(strTame: "abcccd",
		   strWild: "*ccd",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "mississipissippi",
		   strWild: "*issip*ss*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "xxxx*zzzzzzzzy*f",
		   strWild: "xxxx*zzy*fffff",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "xxxx*zzzzzzzzy*f",
		   strWild: "xxx*zzy*f",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "xxxxzzzzzzzzyf",
		   strWild: "xxxx*zzy*fffff",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "xxxxzzzzzzzzyf",
		   strWild: "xxxx*zzy*f",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "xyxyxyzyxyz",
		   strWild: "xy*z*xyz",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "mississippi",
		   strWild: "*sip*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "xyxyxyxyz",
		   strWild: "xy*xyz",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "mississippi",
		   strWild: "mi*sip*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "ababac",
		   strWild: "*abac*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "ababac",
		   strWild: "*abac*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "aaazz",
		   strWild: "a*zz*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "a12b12",
		   strWild: "*12*23",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "a12b12",
		   strWild: "a12b",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "a12b12",
		   strWild: "*12*12*",
		   bExpectedResult: true)

		if !bComparePerformance
		{
			// From DDJ reader Andy Belf: a case of repeating text matching 
			// the different kinds of wildcards in order of '*' and then '?'.
			bAllPassed &&= test(strTame: "caaab",
			                    strWild: "*a?b",
			                    bExpectedResult: true)

			// This similar case was found, probably independently, by Dogan 
			// Kurt.
			bAllPassed &&= test(strTame: "aaaaa",
			                    strWild: "*aa?",
			                    bExpectedResult: true)
		}

		// Additional cases where the '*' char appears in the tame string.
		bAllPassed &&= test(strTame: "*",
		   strWild: "*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "a*abab",
		   strWild: "a*b",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "a*r",
		   strWild: "a*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "a*ar",
		   strWild: "a*aar",
		   bExpectedResult: false)

		// More double wildcard scenarios.
		bAllPassed &&= test(strTame: "XYXYXYZYXYz",
		   strWild: "XY*Z*XYz",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "missisSIPpi",
		   strWild: "*SIP*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "mississipPI",
		   strWild: "*issip*PI",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "xyxyxyxyz",
		   strWild: "xy*xyz",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "miSsissippi",
		   strWild: "mi*sip*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abAbac",
		   strWild: "*Abac*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abAbac",
		   strWild: "*Abac*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "aAazz",
		   strWild: "a*zz*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "A12b12",
		   strWild: "*12*23",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "a12B12",
		   strWild: "*12*12*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "oWn",
		   strWild: "*oWn*",
		   bExpectedResult: true)

		// Completely tame (no wildcards) cases.
		bAllPassed &&= test(strTame: "bLah",
		   strWild: "bLah",
		   bExpectedResult: true)

		// Simple mixed wildcard tests suggested by Marlin Deckert.
		bAllPassed &&= test(strTame: "a",
		   strWild: "*?",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "ab",
		   strWild: "*?",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abc",
		   strWild: "*?",
		   bExpectedResult: true)

		// More mixed wildcard tests including coverage for false positives.
		bAllPassed &&= test(strTame: "a",
		   strWild: "??",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "ab",
		   strWild: "?*?",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "ab",
		   strWild: "*?*?*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abc",
		   strWild: "?**?*?",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abc",
		   strWild: "?**?*&?",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "abcd",
		   strWild: "?b*??",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abcd",
		   strWild: "?a*??",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "abcd",
		   strWild: "?**?c?",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abcd",
		   strWild: "?**?d?",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "abcde",
		   strWild: "?*b*?*d*?",
		   bExpectedResult: true)

		// Single-character-match cases.
		bAllPassed &&= test(strTame: "bLah",
		   strWild: "bL?h",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "bLaaa",
		   strWild: "bLa?",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "bLah",
		   strWild: "bLa?",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "bLaH",
		   strWild: "?LaH",
		   bExpectedResult: true)
		
		bCaseInsensitivityCheck = true;
		bAllPassed &&= test(strTame: "bLaH",
		   strWild: "?Lah",	
		   bExpectedResult: bTestCaseInsensitive)
		bCaseInsensitivityCheck = false;

		// Many-wildcard scenarios.
		bAllPassed &&= test(
		   strTame: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab",
		   strWild: "a*a*a*a*a*a*aa*aaa*a*a*b",
		   bExpectedResult: true)
		bAllPassed &&= test(
		   strTame: "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
		   strWild: "*a*b*ba*ca*a*aa*aaa*fa*ga*b*",
		   bExpectedResult: true)
		bAllPassed &&= test(
		   strTame: "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
		   strWild: "*a*b*ba*ca*a*x*aaa*fa*ga*b*",
		   bExpectedResult: false)
		bAllPassed &&= test(
		   strTame: "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
		   strWild: "*a*b*ba*ca*aaaa*fa*ga*gggg*b*",
		   bExpectedResult: false)
		bAllPassed &&= test(
		   strTame: "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
		   strWild: "*a*b*ba*ca*aaaa*fa*ga*ggg*b*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "aaabbaabbaab",
		   strWild: "*aabbaa*a*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*",
		   strWild: "a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "aaaaaaaaaaaaaaaaa",
		   strWild: "*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "aaaaaaaaaaaaaaaa",
		   strWild: "*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*a*",
		   bExpectedResult: false)
		bAllPassed &&= test(
		   strTame: "abc*abcd*abcde*abcdef*abcdefg*abcdefgh*abcdefghi*abcdefghij*abcdefghijk*abcdefghijkl*abcdefghijklm*abcdefghijklmn",
		   strWild: "abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*a            bc*",
		   bExpectedResult: false)
		bAllPassed &&= test(
		   strTame: "abc*abcd*abcde*abcdef*abcdefg*abcdefgh*abcdefghi*abcdefghij*abcdefghijk*abcdefghijkl*abcdefghijklm*abcdefghijklmn",
		   strWild: "abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abc*abcd*abcd*abc*abcd",
		   strWild: "abc*abc*abc*abc*abc",
		   bExpectedResult: false)
		bAllPassed &&= test(
			strTame: "abc*abcd*abcd*abc*abcd*abcd*abc*abcd*abc*abc*abcd",
			strWild: "abc*abc*abc*abc*abc*abc*abc*abc*abc*abc*abcd",
		    bExpectedResult: true)
		bAllPassed &&= test(strTame: "abc",
			strWild: "********a********b********c********",
		    bExpectedResult: true)
		bAllPassed &&= test(strTame: "********a********b********c********",
			strWild: "abc",
		    bExpectedResult: false)
		bAllPassed &&= test(strTame: "abc",
			strWild: "********a********b********b********",
		    bExpectedResult: false)
		bAllPassed &&= test(strTame: "*abc*",
		    strWild: "***a*b*c***",
		    bExpectedResult: true)

		// Case-insensitive algorithm tests.
		if (bTestCaseInsensitive)
		{
			bCaseInsensitivityCheck = true;
			bAllPassed &&= test(strTame: "mississippi",
			                    strWild: "*issip*PI",
				                bExpectedResult: true)
			bAllPassed &&= test(strTame: "miSsissippi",
			                    strWild: "mi*Sip*",
			                    bExpectedResult: true)
			bAllPassed &&= test(strTame: "bLah", 
			                    strWild: "bLaH",
				                bExpectedResult: true)
			bCaseInsensitivityCheck = false;
		}

		// Tests suggested by other DDJ readers.
		bAllPassed &&= test(strTame: "", strWild: "?", bExpectedResult: false)
		bAllPassed &&= test(strTame: "", strWild: "*?", bExpectedResult: false)
		bAllPassed &&= test(strTame: "", strWild: "", bExpectedResult: true)
		bAllPassed &&= test(strTame: "a", strWild: "", bExpectedResult: false)
	}

	if bAllPassed
	{
		print("Passed wildcard tests")
	}
	else
	{
		print("Failed wildcard tests")
	}
}

// A set of tests with (almost) no '*' wildcards.
func testtame()
{
	var iReps: Int
	var bAllPassed: Bool = true

	if bComparePerformance
	{
		// Can choose as many repetitions as you might expect in production.
		iReps = 1000000
	}
	else
	{
		iReps = 1
	}
	
	while iReps > 0
	{
		iReps -= 1

		// Case with last character mismatch.
		bAllPassed &&= test(strTame: "abc",
		   strWild: "abd",
		   bExpectedResult: false)

		// Cases with repeating character sequences.
		bAllPassed &&= test(strTame: "abcccd",
		   strWild: "abcccd",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "mississipissippi",
		   strWild: "mississipissippi",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "xxxxzzzzzzzzyf",
		   strWild: "xxxxzzzzzzzzyfffff",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "xxxxzzzzzzzzyf",
		   strWild: "xxxxzzzzzzzzyf",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "xxxxzzzzzzzzyf",
		   strWild: "xxxxzzy.fffff",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "xxxxzzzzzzzzyf",
		   strWild: "xxxxzzzzzzzzyf",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "xyxyxyzyxyz",
		   strWild: "xyxyxyzyxyz",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "mississippi",
		   strWild: "mississippi",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "xyxyxyxyz",
		   strWild: "xyxyxyxyz",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "m ississippi",
		   strWild: "m ississippi",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "ababac",
		   strWild: "ababac?",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "dababac",
		   strWild: "ababac",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "aaazz",
		   strWild: "aaazz",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "a12b12",
		   strWild: "1212",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "a12b12",
		   strWild: "a12b",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "a12b12",
		   strWild: "a12b12",
		   bExpectedResult: true)

		// A mix of cases
		bAllPassed &&= test(strTame: "n",
		   strWild: "n",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "aabab",
		   strWild: "aabab",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "ar",
		   strWild: "ar",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "aar",
		   strWild: "aaar",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "XYXYXYZYXYz",
		   strWild: "XYXYXYZYXYz",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "missisSIPpi",
		   strWild: "missisSIPpi",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "mississipPI",
		   strWild: "mississipPI",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "xyxyxyxyz",
		   strWild: "xyxyxyxyz",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "miSsissippi",
		   strWild: "miSsissippi",
		   bExpectedResult: true)
			
		if bTestCaseInsensitive
		{
			bCaseInsensitivityCheck = true;
			bAllPassed &&= test(strTame: "miSsissippi",
			                    strWild: "miSsisSippi",
			                    bExpectedResult: true)
			bAllPassed &&= test(strTame: "abAbac",
			                    strWild: "abAbac",
			                    bExpectedResult: true)
			bAllPassed &&= test(strTame: "abAbac",
			                    strWild: "abAbac",
			                    bExpectedResult: true)
			bAllPassed &&= test(strTame: "bLah",
			                    strWild: "bLaH",
			                    bExpectedResult: true)
			bCaseInsensitivityCheck = false;
		}

		bAllPassed &&= test(strTame: "aAazz",
		   strWild: "aAazz",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "A12b12",
		   strWild: "A12b123",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "a12B12",
		   strWild: "a12B12",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "oWn",
		   strWild: "oWn",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "bLah",
		   strWild: "bLah",
		   bExpectedResult: true)

		// Single '?' cases.
		bAllPassed &&= test(strTame: "a",
		   strWild: "a",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "ab",
		   strWild: "a?",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abc",
		   strWild: "ab?",
		   bExpectedResult: true)

		// Mixed '?' cases.
		bAllPassed &&= test(strTame: "a",
		   strWild: "??",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "ab",
		   strWild: "??",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abc",
		   strWild: "???",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abcd",
		   strWild: "????",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abc",
		   strWild: "????",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "abcd",
		   strWild: "?b??",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abcd",
		   strWild: "?a??",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "abcd",
		   strWild: "??c?",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "abcd",
		   strWild: "??d?",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "abcde",
		   strWild: "?b?d*?",
		   bExpectedResult: true)

		// Longer string scenarios.
		bAllPassed &&= test(
		   strTame: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab",
		   strWild: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab",
		   bExpectedResult: true)
		bAllPassed &&= test(
		   strTame: "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
		   strWild: "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
		   bExpectedResult: true)
		bAllPassed &&= test(
		   strTame: "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
		   strWild: "abababababababababababababababababababaacacacacacacacadaeafagahaiajaxalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
		   bExpectedResult: false)
		bAllPassed &&= test(
		   strTame: "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
		   strWild: "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaggggagaaaaaaaab",
		   bExpectedResult: false)
		bAllPassed &&= test(
		   strTame: "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
		   strWild: "abababababababababababababababababababaacacacacacacacadaeafagahaiajakalaaaaaaaaaaaaaaaaaffafagaagggagaaaaaaaab",
		   bExpectedResult: true)
		bAllPassed &&= test(
		   strTame: "aaabbaabbaab",
		   strWild: "aaabbaabbaab",
		   bExpectedResult: true)
		bAllPassed &&= test(
		   strTame: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		   strWild: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		   bExpectedResult: true)
		bAllPassed &&= test(
		   strTame: "aaaaaaaaaaaaaaaaa",
		   strWild: "aaaaaaaaaaaaaaaaa",
		   bExpectedResult: true)
		bAllPassed &&= test(
		   strTame: "aaaaaaaaaaaaaaaa",
		   strWild: "aaaaaaaaaaaaaaaaa",
		   bExpectedResult: false)
		bAllPassed &&= test(
		   strTame: "abcabcdabcdeabcdefabcdefgabcdefghabcdefghiabcdefghijabcdefghijkabcdefghijklabcdefghijklmabcdefghijklmn",
		   strWild: "abcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabc",
		   bExpectedResult: false)
		bAllPassed &&= test(
		   strTame: "abcabcdabcdeabcdefabcdefgabcdefghabcdefghiabcdefghijabcdefghijkabcdefghijklabcdefghijklmabcdefghijklmn",
		   strWild: "abcabcdabcdeabcdefabcdefgabcdefghabcdefghiabcdefghijabcdefghijkabcdefghijklabcdefghijklmabcdefghijklmn",
		   bExpectedResult: true)
		bAllPassed &&= test(
		   strTame: "abcabcdabcdabcabcd",
		   strWild: "abcabc?abcabcabc",
		   bExpectedResult: false)
		bAllPassed &&= test(
		   strTame: "abcabcdabcdabcabcdabcdabcabcdabcabcabcd",
		   strWild: "abcabc?abc?abcabc?abc?abc?bc?abc?bc?bcd",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "?abc?",
		   strWild: "?abc?",
		   bExpectedResult: true)
	}

	if bAllPassed
	{
		print("Passed tame string tests")
	}
	else
	{
		print("Failed tame string tests")
	}
}

// A set of tests with empty input.
func testempty()
{
	var iReps: Int
	var bAllPassed: Bool = true

	if bComparePerformance
	{
		// Can choose as many repetitions as you might expect in production.
		iReps = 1000000
	}
	else
	{
		iReps = 1
	}

	while iReps > 0
	{
		iReps -= 1

		// A simple case.
		bAllPassed &&= test(strTame: "",
		   strWild: "abd",
		   bExpectedResult: false)

		// Cases with repeating character sequences.
		bAllPassed &&= test(strTame: "",
		   strWild: "abcccd",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "mississipissippi",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "xxxxzzzzzzzzyfffff",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "xxxxzzzzzzzzyf",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "xxxxzzy.fffff",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "xxxxzzzzzzzzyf",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "xyxyxyzyxyz",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "mississippi",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "xyxyxyxyz",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "m ississippi",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "ababac*",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "ababac",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "aaazz",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "1212",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "a12b",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "a12b12",
		   bExpectedResult: false)

		// A mix of cases.
		bAllPassed &&= test(strTame: "",
		   strWild: "n",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "aabab",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "ar",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "aaar",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "XYXYXYZYXYz",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "missisSIPpi",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "mississipPI",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "xyxyxyxyz",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "miSsissippi",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "miSsisSippi",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "abAbac",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "abAbac",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "aAazz",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "A12b123",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "a12B12",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "oWn",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "bLah",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "",
		   strWild: "bLaH",
		   bExpectedResult: false)

		// Both strings empty.
		bAllPassed &&= test(strTame: "",
		   strWild: "",
		   bExpectedResult: true)

		// Another simple case.
		bAllPassed &&= test(strTame: "abc",
		   strWild: "",
		   bExpectedResult: false)

		// More cases with repeating character sequences.
		bAllPassed &&= test(strTame: "abcccd",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "mississipissippi",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "xxxxzzzzzzzzyf",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "xxxxzzzzzzzzyf",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "xxxxzzzzzzzzyf",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "xxxxzzzzzzzzyf",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "xyxyxyzyxyz",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "mississippi",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "xyxyxyxyz",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "m ississippi",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "ababac",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "dababac",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "aaazz",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "a12b12",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "a12b12",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "a12b12",
		   strWild: "",
		   bExpectedResult: false)

		// Another mix of cases.
		bAllPassed &&= test(strTame: "n",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "aabab",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "ar",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "aar",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "XYXYXYZYXYz",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "missisSIPpi",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "mississipPI",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "xyxyxyxyz",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "miSsissippi",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "miSsissippi",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "abAbac",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "abAbac",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "aAazz",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "A12b12",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "a12B12",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "oWn",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "bLah",
		   strWild: "",
		   bExpectedResult: false)
		bAllPassed &&= test(strTame: "bLah",
		   strWild: "",
		   bExpectedResult: false)
	}

	if bAllPassed
	{
		print("Passed empty string tests")
	}
	else
	{
		print("Failed empty string tests")
	}
}

// Correctness tests for a case-sensitive arrangement for invoking a
// UTF-8-enabled routine for matching wildcards.  See relevant code /
// comments in test().
func testutf8()
{
	var bAllPassed: Bool = true

	// Simple correctness tests involving various UTF-8 symbols and
	// international content.
	bAllPassed &&= test(strTame: "🐂🚀♥🍀貔貅🦁★□√🚦€¥☯🐴😊🍓🐕🎺🧊☀☂🐉",
	   strWild: "*☂🐉",
	   bExpectedResult: true)

	if bTestCaseInsensitive
	{
		bCaseInsensitivityCheck = true;
		bAllPassed &&= test(strTame: "AbCD",
		   strWild: "abc?",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "AbC★",
		   strWild: "abc?",
		   bExpectedResult: true)
		bAllPassed &&= test(strTame: "⚛⚖☁o",
		   strWild: "⚛⚖☁O",
		   bExpectedResult: true)
		bCaseInsensitivityCheck = false;
	}

	bAllPassed &&= test(strTame: "▲●🐎✗🤣🐶♫🌻ॐ",
	   strWild: "▲●☂*",
	   bExpectedResult: false)
	bAllPassed &&= test(strTame: "𓋍𓋔𓎍",
	   strWild: "𓋍𓋔?",
	   bExpectedResult: true)
	bAllPassed &&= test(strTame: "𓋍𓋔𓎍",
	   strWild: "𓋍?𓋔𓎍",
	   bExpectedResult: false)
	bAllPassed &&= test(strTame: "♅☌♇",
	   strWild: "♅☌♇",
	   bExpectedResult: true)
	bAllPassed &&= test(strTame: "⚛⚖☁",
	   strWild: "⚛🍄☁",
	   bExpectedResult: false)
	bAllPassed &&= test(strTame: "⚛⚖☁O",
	   strWild: "⚛⚖☁0",
	   bExpectedResult: false)

	// This test fails a wildcard match that relies on extended grapheme 
	// clusters; i.e. without Swift's .unicodescalars string representation.
	bAllPassed &&= test(strTame: "गते गते पारगते पारसंगते बोधि स्वाहा",
	   strWild: "गते गते पारगते प????गते बोधि स्वाहा",
	   bExpectedResult: true)

	bAllPassed &&= test(
	   strTame: "Мне нужно выучить русский язык, чтобы лучше оценить Пушкина.",
	   strWild: "Мне нужно выучить * язык, чтобы лучше оценить *.",
	   bExpectedResult: true)
	bAllPassed &&= test(
	  strTame: "אני צריך ללמוד אנגלית כדי להעריך את גינסברג",
	  strWild: " אני צריך ללמוד אנגלית כדי להעריך את ???????",
	  bExpectedResult: false)
	bAllPassed &&= test(
	  strTame: "ગિન્સબર્ગની શ્રેષ્ઠ પ્રશંસા કરવા માટે મારે અંગ્રેજી શીખવું પડશે.",
	  strWild: "* શ્રેષ્ઠ પ્રશંસા કરવા માટે મારે * શીખવું પડશે.",
	  bExpectedResult: true)
	bAllPassed &&= test(
	  strTame: "ગિન્સબર્ગની શ્રેષ્ઠ પ્રશંસા કરવા માટે મારે અંગ્રેજી શીખવું પડશે.",
	  strWild: "??????????? શ્રેષ્ઠ પ્રશંસા કરવા માટે મારે * શીખવું પડશે.",
	  bExpectedResult: true)
	bAllPassed &&= test(
	  strTame: "ગિન્સબર્ગની શ્રેષ્ઠ પ્રશંસા કરવા માટે મારે અંગ્રેજી શીખવું પડશે.",
	  strWild: "ગિન્સબર્ગની શ્રેષ્ઠ પ્રશંસા કરવા માટે મારે હિબ્રુ ભાષા શીખવી પડશે.",
	  bExpectedResult: false)

	// These tests involve multiple=byte code points that contain bytes
	// identical to the single-byte code points for '*' and '?'.
	bAllPassed &&= test(
	   strTame: "ḪؿꜪἪꜿ", 
	   strWild: "ḪؿꜪἪꜿ", 
	   bExpectedResult: true)
	bAllPassed &&= test(strTame: "ḪؿUἪꜿ",
		   strWild: "ḪؿꜪἪꜿ",
		   bExpectedResult: false)
	bAllPassed &&= test(strTame: "ḪؿꜪἪꜿ",
		   strWild: "ḪؿꜪἪꜿЖ",
		   bExpectedResult: false)
	bAllPassed &&= test(strTame: "ḪؿꜪἪꜿ",
		   strWild: "ЬḪؿꜪἪꜿ",
		   bExpectedResult: false)
	bAllPassed &&= test(strTame: "ḪؿꜪἪꜿ",
		   strWild: "?ؿꜪ*ꜿ",
		   bExpectedResult: true)

	if bAllPassed
	{
		print("Passed UTF-8 tests")
	}
	else
	{
		print("Failed UTF-8 tests")
	}
}

@main
struct wild
{
    static func main()
	{
		// Accumulate timing data for all implementations invoked in test().
		if bTestTame
		{
			testtame()
		}

		if bTestEmpty
		{
			testempty()
		}

		if bTestWild
		{
			testwild()
		}

		if bTestUtf8
		{
			testutf8()
		}

		if bComparePerformance
		{
			// Timings have been accumulated via package-scope data.
			let fBase: Double = 10.0
			let fExpNanoseconds: Double = 9.0
			let fExpMilliseconds: Double = 3.0

			// Represent the timings in seconds, to millisecond precision.
			let fTimeCumulativeCaseSensitiveVersion: Double = 
				(Double(iAccumulatedTimeCaseSensitive) / 
					pow(fBase, fExpNanoseconds)) * 
						pow(fBase, fExpMilliseconds)
			let fTimeCumulativeCaseInsensitiveVersion: Double = 
				(Double(iAccumulatedTimeCaseInsensitive) /
					pow(fBase, fExpNanoseconds)) * 
						pow(fBase, fExpMilliseconds)
			// Can add similar calculations for more performance comparisons...

			let fCaseSensitiveVersionTimeInSeconds: Double = 
					fTimeCumulativeCaseSensitiveVersion / 1000
			let fCaseInsensitiveVersionTimeInSeconds: Double = 
					fTimeCumulativeCaseInsensitiveVersion / 1000
			let formattedOutput = String(format: "%.3f", 
			        fCaseSensitiveVersionTimeInSeconds);
			let formattedOutputCase = String(format: "%.3f", 
			        fCaseInsensitiveVersionTimeInSeconds);

			// Show the timing results.
			print(
			 "FastWildCompare() - for UTF-8-encoded Strings: " + 
			      formattedOutput + " seconds")
			// Can add results for more performance comparisons here...
			print(
			  "FastWildCaseCompare() - for UTF-8-encoded Strings: " + 
			      formattedOutputCase + " seconds")
		}
    }
}
