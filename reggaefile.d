import reggae;

enum testFlags = "-g -debug -w";

alias ut = dubTestTarget!(CompilerFlags(testFlags));
alias example = dubConfigurationTarget!(Configuration("example"),
                                        CompilerFlags(testFlags));

mixin build!(ut, example);
