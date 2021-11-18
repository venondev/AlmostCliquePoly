module CppWCE
  using CxxWrap
  @wrapmodule(normpath(joinpath(@__DIR__, "../../WCELib/build/lib","libwce")))

  function __init__()
    @initcxx
  end
end