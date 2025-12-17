// UTF-8-ready Swift routines for matching wildcards.
//
// Copyright 2025 Kirk J Krauss.  This is a Derivative Work based on 
// material that is copyright 2025 Kirk J Krauss and available at
//
//     https://developforperformance.com/MatchingWildcards_AnImprovedAlgorithmForBigData.html
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     https://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// String exention for debug logging.
extension String {
    func hexEncodedString() -> String {
        return self.data(using: .utf8)?
            .map { String(format: "%02x", $0) }
            .joined() ?? ""
    }
}

// Case-sensitive Swift implementation of FastWildCompare().
//
// Compares two Strings.  Accepts "?" as a single-code-point wildcard.  For 
// each "*" wildcard, seeks out a matching sequence of any code points beyond 
// it.  Otherwise compares the Strings a code point at a time.
//
func FastWildCompare(strWild: String /* may have wildcards */,
                     strTame: String /* no wildcards */
                ) -> Bool
{
	var iWild = strWild.unicodeScalars.startIndex   // Index for wild content
	var iTame = strTame.unicodeScalars.startIndex   // Index for tame content
	var iWildSequence: String.Index  // Index for prospective match after '*'
	var iTameSequence: String.Index  // Index for match in tame content

    // Find a first wildcard, if one exists, and the beginning of any  
    // prospectively matching sequence after it.
    repeat
	{
		// Check for the end from the start.  Get out fast, if possible.
		if strTame.unicodeScalars.endIndex == iTame
		{
			if strWild.unicodeScalars.endIndex != iWild
			{
				while strWild.unicodeScalars[iWild] == "*"
				{
					iWild = strWild.unicodeScalars.index(after: iWild)
					
					if strWild.unicodeScalars.endIndex == iWild
					{
						return true          // "ab" matches "ab*".
					}
				}

			    return false                 // "abcd" doesn't match "abc".
			} else {
				return true                  // "abc" matches "abc".
			}
		}
		else if strWild.unicodeScalars.endIndex == iWild
		{
		    return false                     // "abc" doesn't match "abcd".
		}
		else if strWild.unicodeScalars[iWild] == "*"
		{
			// Got wild: set up for the second loop and skip on down there.
			repeat
			{
				iWild = strWild.unicodeScalars.index(after: iWild)

				if strWild.unicodeScalars.endIndex == iWild
				{
					return true              // "abc*" matches "abcd".
				}
				
				if strWild.unicodeScalars[iWild] != "*"
				{
					break
				}
			} while true

			// Search for the next prospective match.
			if strWild.unicodeScalars[iWild] != "?"
			{
				while strWild.unicodeScalars[iWild] != 
				         strTame.unicodeScalars[iTame]
				{
					iTame = strTame.unicodeScalars.index(after: iTame)

					if strTame.unicodeScalars.endIndex == iTame
					{
						return false         // "a*bc" doesn't match "ab".
					}
				}
			}

			// Keep fallback positions for retry in case of incomplete match.
			iWildSequence = iWild
			iTameSequence = iTame
			break
		}
		else if strWild.unicodeScalars[iWild] != 
		           strTame.unicodeScalars[iTame] && 
				      strWild.unicodeScalars[iWild] != "?"
		{
			return false                     // "abc" doesn't match "abd".
		}

		// Everything's a match, so far.
		iWild = strWild.unicodeScalars.index(after: iWild)
		iTame = strTame.unicodeScalars.index(after: iTame)
	} while true

    // Find any further wildcards and any further matching sequences.
    repeat
	{
		if strWild.unicodeScalars.endIndex != iWild && 
		   strWild.unicodeScalars[iWild] == "*"
		{
            // Got wild again.
			repeat
			{
				iWild = strWild.unicodeScalars.index(after: iWild)

				if strWild.unicodeScalars.endIndex == iWild
				{
					return true              // "abc*" matches "abcd".
				}
				
				if strWild.unicodeScalars[iWild] != "*"
				{
					break
				}
			} while true

			if strTame.unicodeScalars.endIndex == iTame
			{
                return false                 // "*bcd*" doesn't match "abc".
            }

            // Search for the next prospective match.
            if strWild[iWild] != "?"
			{
                while strWild.unicodeScalars[iWild] != 
				         strTame.unicodeScalars[iTame]
				{
					iTame = strTame.unicodeScalars.index(after: iTame)

                    if strTame.unicodeScalars.endIndex == iTame
					{
                        return false         // "a*b*c" doesn't match "ab".
                    }
                }
            }

            // Keep the new fallback positions.
			iWildSequence = iWild
			iTameSequence = iTame
        }
		else
		{
            // The equivalent portion of the upper loop is really simple.
            if strTame.unicodeScalars.endIndex == iTame
			{
				if strWild.unicodeScalars.endIndex == iWild
				{
					return true              // "*b*c" matches "abc".
				}
			
                return false                 // "*bcd" doesn't match "abc".
            }

			if strWild.unicodeScalars.endIndex == iWild || 
			    (strWild.unicodeScalars[iWild] != 
				    strTame.unicodeScalars[iTame] && 
					   strWild.unicodeScalars[iWild] != "?")
			{
				// A fine time for questions.
				while strWild.unicodeScalars.endIndex != iWildSequence && 
				    strWild[iWildSequence] == "?"
				{
					iWildSequence = 
					       strWild.unicodeScalars.index(after: iWildSequence)
					iTameSequence = 
					       strTame.unicodeScalars.index(after: iTameSequence)
				}

				iWild = iWildSequence

				// Fall back, but never so far again.
				repeat
				{
					iTameSequence = 
					       strTame.unicodeScalars.index(after: iTameSequence)

					if strTame.unicodeScalars.endIndex == iTameSequence
					{
						if strWild.endIndex == iWild
						{
							return true      // "*a*b" matches "ab".
						}
						else
						{
							return false     // "*a*b" doesn't match "ac".
						}
					}

					if strWild.unicodeScalars.endIndex != iWild &&
					   strWild.unicodeScalars[iWild] == 
					      strTame.unicodeScalars[iTameSequence]
					{
						break
					}
				} while true

	            iTame = iTameSequence
			}
        }

        // Another check for the end, at the end.
        if strTame.unicodeScalars.endIndex == iTame
		{
			if strWild.unicodeScalars.endIndex == iWild
			{
				return true                  // "*bc" matches "abc".
			}

			return false                     // "*bc" doesn't match "abcd".
		}

		iWild = strWild.unicodeScalars.index(after: iWild)  // Everything's still a match.
		iTame = strTame.unicodeScalars.index(after: iTame)
    } while true
}

// Case-insensitive Swift implementation of FastWildCompare().
//
// Compares two Strings.  Accepts "?" as a single-code-point wildcard.  For 
// each "*" wildcard, seeks out a matching sequence of any code points beyond 
// it.  Otherwise compares the Strings a code point at a time.
//
func FastWildCaseCompare(strWild: String /* may have wildcards */,
                         strTame: String /* no wildcards */
                ) -> Bool
{
	var iWild = strWild.unicodeScalars.startIndex   // Index for wild content
	var iTame = strTame.unicodeScalars.startIndex   // Index for tame content
	var iWildSequence: String.Index  // Index for prospective match after '*'
	var iTameSequence: String.Index  // Index for match in tame content

    // Find a first wildcard, if one exists, and the beginning of any  
    // prospectively matching sequence after it.
    repeat
	{
		// Check for the end from the start.  Get out fast, if possible.
		if strTame.unicodeScalars.endIndex == iTame
		{
			if strWild.unicodeScalars.endIndex != iWild
			{
				while strWild.unicodeScalars[iWild] == "*"
				{
					iWild = strWild.unicodeScalars.index(after: iWild)
					
					if strWild.unicodeScalars.endIndex == iWild
					{
						return true          // "ab" matches "ab*".
					}
				}

			    return false                 // "abcd" doesn't match "abc".
			} else {
				return true                  // "abc" matches "abc".
			}
		}
		else if strWild.unicodeScalars.endIndex == iWild
		{
		    return false                     // "abc" doesn't match "abcd".
		}
		else if strWild.unicodeScalars[iWild] == "*"
		{
			// Got wild: set up for the second loop and skip on down there.
			repeat
			{
				iWild = strWild.unicodeScalars.index(after: iWild)

				if strWild.unicodeScalars.endIndex == iWild
				{
					return true              // "abc*" matches "abcd".
				}
				
				if strWild.unicodeScalars[iWild] != "*"
				{
					break
				}
			} while true

			// Search for the next prospective match.
			if strWild.unicodeScalars[iWild] != "?"
			{
				while Character(strWild.unicodeScalars[iWild]).lowercased() != 
				      Character(strTame.unicodeScalars[iTame]).lowercased()
				{
					iTame = strTame.unicodeScalars.index(after: iTame)

					if strTame.unicodeScalars.endIndex == iTame
					{
						return false         // "a*bc" doesn't match "ab".
					}
				}
			}

			// Keep fallback positions for retry in case of incomplete match.
			iWildSequence = iWild
			iTameSequence = iTame
			break
		}
		else if Character(strWild.unicodeScalars[iWild]).lowercased() != 
		        Character(strTame.unicodeScalars[iTame]).lowercased() && 
				      strWild.unicodeScalars[iWild] != "?"
		{
			return false                     // "abc" doesn't match "abd".
		}

		// Everything's a match, so far.
		iWild = strWild.unicodeScalars.index(after: iWild)
		iTame = strTame.unicodeScalars.index(after: iTame)
	} while true

    // Find any further wildcards and any further matching sequences.
    repeat
	{
		if strWild.unicodeScalars.endIndex != iWild && 
		   strWild.unicodeScalars[iWild] == "*"
		{
            // Got wild again.
			repeat
			{
				iWild = strWild.unicodeScalars.index(after: iWild)

				if strWild.unicodeScalars.endIndex == iWild
				{
					return true              // "abc*" matches "abcd".
				}
				
				if strWild.unicodeScalars[iWild] != "*"
				{
					break
				}
			} while true

			if strTame.unicodeScalars.endIndex == iTame
			{
                return false                 // "*bcd*" doesn't match "abc".
            }

            // Search for the next prospective match.
            if strWild[iWild] != "?"
			{
                while Character(strWild.unicodeScalars[iWild]).lowercased() != 
				      Character(strTame.unicodeScalars[iTame]).lowercased()
				{
					iTame = strTame.unicodeScalars.index(after: iTame)

                    if strTame.unicodeScalars.endIndex == iTame
					{
                        return false         // "a*b*c" doesn't match "ab".
                    }
                }
            }

            // Keep the new fallback positions.
			iWildSequence = iWild
			iTameSequence = iTame
        }
		else
		{
            // The equivalent portion of the upper loop is really simple.
            if strTame.unicodeScalars.endIndex == iTame
			{
				if strWild.unicodeScalars.endIndex == iWild
				{
					return true              // "*b*c" matches "abc".
				}
			
                return false                 // "*bcd" doesn't match "abc".
            }

			if strWild.unicodeScalars.endIndex == iWild || 
			    (Character(strWild.unicodeScalars[iWild]).lowercased() != 
				 Character(strTame.unicodeScalars[iTame]).lowercased() && 
					   strWild.unicodeScalars[iWild] != "?")
			{
				// A fine time for questions.
				while strWild.unicodeScalars.endIndex != iWildSequence && 
				    strWild[iWildSequence] == "?"
				{
					iWildSequence = 
					       strWild.unicodeScalars.index(after: iWildSequence)
					iTameSequence = 
					       strTame.unicodeScalars.index(after: iTameSequence)
				}

				iWild = iWildSequence

				// Fall back, but never so far again.
				repeat
				{
					iTameSequence = 
					       strTame.unicodeScalars.index(after: iTameSequence)

					if strTame.unicodeScalars.endIndex == iTameSequence
					{
						if strWild.endIndex == iWild
						{
							return true      // "*a*b" matches "ab".
						}
						else
						{
							return false     // "*a*b" doesn't match "ac".
						}
					}

					if strWild.unicodeScalars.endIndex != iWild &&
					 Character(strWild.unicodeScalars[iWild]).lowercased() == 
					 Character(strTame.unicodeScalars[iTameSequence]).lowercased()
					{
						break
					}
				} while true

	            iTame = iTameSequence
			}
        }

        // Another check for the end, at the end.
        if strTame.unicodeScalars.endIndex == iTame
		{
			if strWild.unicodeScalars.endIndex == iWild
			{
				return true                  // "*bc" matches "abc".
			}

			return false                     // "*bc" doesn't match "abcd".
		}

		iWild = strWild.unicodeScalars.index(after: iWild)  // Everything's still a match.
		iTame = strTame.unicodeScalars.index(after: iTame)
    } while true
}
