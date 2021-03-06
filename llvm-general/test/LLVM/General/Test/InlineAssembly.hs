module LLVM.General.Test.InlineAssembly where

import Test.Framework
import Test.Framework.Providers.HUnit
import Test.HUnit

import LLVM.General.Test.Support

import LLVM.General.Context
import LLVM.General.Module

import LLVM.General.AST
import LLVM.General.AST.InlineAssembly as IA
import qualified LLVM.General.AST.Linkage as L
import qualified LLVM.General.AST.Visibility as V
import qualified LLVM.General.AST.CallingConvention as CC
import qualified LLVM.General.AST.Constant as C
import qualified LLVM.General.AST.Global as G

tests = testGroup "InlineAssembly" [
  testCase "expression" $ do
    let ast = Module "<string>" Nothing Nothing [
                GlobalDefinition $ 
                  functionDefaults {
                    G.returnType = IntegerType 32,
                    G.name = Name "foo",
                    G.parameters = ([Parameter (IntegerType 32) (Name "x") []],False),
                    G.basicBlocks = [
                      BasicBlock (UnName 0) [
                        UnName 1 := Call {
                          isTailCall = False,
                          callingConvention = CC.C,
                          returnAttributes = [],
                          function = Left $ InlineAssembly {
                                       IA.type' = FunctionType (IntegerType 32) [IntegerType 32] False,
                                       assembly = "bswap $0",
                                       constraints = "=r,r",
                                       hasSideEffects = False,
                                       alignStack = False,
                                       dialect = ATTDialect
                                     },
                          arguments = [
                            (LocalReference (Name "x"), [])
                           ],
                          functionAttributes = [],
                          metadata = []
                        }
                      ] (
                        Do $ Ret (Just (LocalReference (UnName 1))) []
                      )
                    ]
                }

              ]
        s = "; ModuleID = '<string>'\n\
             \\n\
             \define i32 @foo(i32 %x) {\n\
             \  %1 = call i32 asm \"bswap $0\", \"=r,r\"(i32 %x)\n\
             \  ret i32 %1\n\
             \}\n"
    strCheck ast s,

  testCase "module" $ do
    let ast = Module "<string>" Nothing Nothing [
                ModuleInlineAssembly "foo",
                ModuleInlineAssembly "bar",
                GlobalDefinition $ globalVariableDefaults {
                  G.name = UnName 0,
                  G.type' = IntegerType 32
                }
              ]
        s = "; ModuleID = '<string>'\n\
             \\n\
             \module asm \"foo\"\n\
             \module asm \"bar\"\n\
             \\n\
             \@0 = external global i32\n"
    strCheck ast s
 ]
