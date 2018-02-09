function fc = analysisFigConstructor(analstr)

if ~isacqpref('AnalysisFigures')
    setacqpref('AnalysisFigures',analstr,[]);
end
fc = getacqpref('AnalysisFigures',analstr);

    