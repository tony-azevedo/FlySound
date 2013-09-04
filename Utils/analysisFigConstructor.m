function fc = analysisFigConstructor(analstr)

if ~ispref('AnalysisFigures')
    setpref('AnalysisFigures',analstr,[]);
end
fc = getpref('AnalysisFigures',analstr);

    