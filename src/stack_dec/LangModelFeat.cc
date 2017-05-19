/*
thot package for statistical machine translation
Copyright (C) 2013 Daniel Ortiz-Mart\'inez
 
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.
 
You should have received a copy of the GNU Lesser General Public License
along with this program; If not, see <http://www.gnu.org/licenses/>.
*/
 
/********************************************************************/
/*                                                                  */
/* Module: LangModelFeat                                            */
/*                                                                  */
/* Definitions file: LangModelFeat.cc                               */
/*                                                                  */
/********************************************************************/


//--------------- Include files --------------------------------------

#include "LangModelFeat.h"

//--------------- LangModelFeat class functions

template<>
typename LangModelFeat<PhrScoreInfo>::HypScoreInfo
LangModelFeat<PhrScoreInfo>::extensionScore(const Vector<std::string>& srcSent,
                                            const HypScoreInfo& predHypScrInf,
                                            const PhrHypDataStr& predHypDataStr,
                                            const PhrHypDataStr& newHypDataStr,
                                            Score& unweightedScore)
{
      // Check if function was called to score the null hypothesis
  if(predHypDataStr.sourceSegmentation.empty() && newHypDataStr.sourceSegmentation.empty())
  {
        // Obtain language model state for null hypothesis
    HypScoreInfo hypScrInf=predHypScrInf;
    lModelPtr->getStateForBeginOfSentence(hypScrInf.lmHist);
    return hypScrInf;
  }
  else
  {
        // Obtain score for hypothesis extension
    HypScoreInfo hypScrInf=predHypScrInf;
    unweightedScore=0;
    
    for(unsigned int i=predHypDataStr.sourceSegmentation.size();i<newHypDataStr.sourceSegmentation.size();++i)
    {
          // Initialize variables
      unsigned int trgLeft;
      unsigned int trgRight=newHypDataStr.targetSegmentCuts[i];
      if(i==0)
        trgLeft=1;
      else
        trgLeft=newHypDataStr.targetSegmentCuts[i-1]+1;
      Vector<std::string> trgPhrase;
      for(unsigned int k=trgLeft;k<=trgRight;++k)
      {
        trgPhrase.push_back(newHypDataStr.ntarget[k]);
      }

          // Update score
      Score iterScore=getNgramScoreGivenState(trgPhrase,hypScrInf.lmHist);
      unweightedScore+= iterScore;
      hypScrInf.score+= weight*iterScore;
    }

        // Check if new hypothesis is complete
    if(numberOfSrcWordsCovered(newHypDataStr)==srcSent.size())
    {
        // Obtain score contribution for complete hypothesis
      Score scrCompl=getEosScoreGivenState(hypScrInf.lmHist);
      unweightedScore+= scrCompl;
      hypScrInf.score+= weight*scrCompl;
    }
    
    return hypScrInf;
  }
}
