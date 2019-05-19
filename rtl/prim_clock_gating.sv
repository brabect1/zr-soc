// Copyright 2019 Tomas Brabec
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// 
// Change log:
//     2019, May, Tomas Brabec
//     - Created.


module prim_clock_gating (
    input  logic clk_i,
    input  logic en_i,
    input  logic test_en_i,
    output logic clk_o
);

logic en;

always_latch begin: p_en
    if (!clk_i) begin
        en <= en_i | test_en_i;
    end
end: p_en

assign clk_o = en & clk_i;

endmodule: prim_clock_gating
