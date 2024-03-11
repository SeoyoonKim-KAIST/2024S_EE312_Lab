`include "vending_machine_def.v"

module vending_machine (

	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)

	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered

	o_available_item,			// Sign of the item availability
	o_output_item,			// Sign of the item withdrawal
	o_return_coin,				// Sign of the coin return
);

	// Ports Declaration
	// Do not modify the module interface
	input clk;
	input reset_n;

	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;

	output reg [`kNumItems-1:0] o_available_item;
	output reg [`kNumItems-1:0] o_output_item;
	output reg [`kNumCoins-1:0] o_return_coin;

	// Normally, every output is register,
	//   so that it can provide stable value to the outside.

//////////////////////////////////////////////////////////////////////	/

	//we have to return many coins
	reg [`kCoinBits-1:0] returning_coin_0;
	reg [`kCoinBits-1:0] returning_coin_1;
	reg [`kCoinBits-1:0] returning_coin_2;
	reg block_item_0;
	reg block_item_1;

	//check timeout
	reg [3:0] stopwatch;

	//when return triggered
	reg have_to_return;
	reg  [`kTotalBits-1:0] return_temp;
	reg [`kTotalBits-1:0] temp;

////////////////////////////////////////////////////////////////////////

	// Net constant values (prefix kk & CamelCase)
	// Please refer the wikepedia webpate to know the CamelCase practive of writing.
	// http://en.wikipedia.org/wiki/CamelCase
	// Do not modify the values.
	wire [31:0] kkItemPrice [`kNumItems-1:0];	// Price of each item
	wire [31:0] kkCoinValue [`kNumCoins-1:0];	// Value of each coin
	assign kkItemPrice[0] = 400;
	assign kkItemPrice[1] = 500;
	assign kkItemPrice[2] = 1000;
	assign kkItemPrice[3] = 2000;
	assign kkCoinValue[0] = 100;
	assign kkCoinValue[1] = 500;
	assign kkCoinValue[2] = 1000;


	// NOTE: integer will never be used other than special usages.
	// Only used for loop iteration.
	// You may add more integer variables for loop iteration.
	integer i, j, k,l,m,n;

	// Internal states. You may add your own net & reg variables.
	reg [`kTotalBits-1:0] current_total;
	reg [`kItemBits-1:0] num_items [`kNumItems-1:0];
	reg [`kCoinBits-1:0] num_coins [`kNumCoins-1:0];

	// Next internal states. You may add your own net and reg variables.
	reg [`kTotalBits-1:0] current_total_nxt;
	reg [`kItemBits-1:0] num_items_nxt [`kNumItems-1:0];
	reg [`kCoinBits-1:0] num_coins_nxt [`kNumCoins-1:0];

	// Variables. You may add more your own registers.
	reg [`kTotalBits-1:0] input_total, output_total, return_total_0,return_total_1,return_total_2;

    reg [3:0] withdrawl_items;                  // Sequential Logic to Output Logic
    reg [3:0] withdrawl_items_nxt;              // Next State Logic to Sequential Logic
    reg timeout_return;                         // Sequential Logic to Next State / Output Logic
    integer ResetTimer;                         // 1: Reset Timer


	// Combinational logic for the next states
	always @(*) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).

        if ((!reset_n)) begin
            current_total_nxt = 0;
            withdrawl_items_nxt = 0;
            num_coins_nxt[0] = 0;
            num_coins_nxt[1] = 0;
            num_coins_nxt[2] = 0;
        end

        if (i_trigger_return || timeout_return) begin
            current_total_nxt = 0;
            withdrawl_items_nxt = 0;

            if (num_coins_nxt[0]) num_coins_nxt[0] = num_coins_nxt[0] - 1;
            else if (num_coins_nxt[1]) num_coins_nxt[1] = num_coins_nxt[1] - 1;
            else if (num_coins_nxt[2]) num_coins_nxt[2] = num_coins_nxt[2] - 1;
            else ;
        end

        withdrawl_items_nxt = 0;    // Initialize after 1 cycle
        ResetTimer = 1;             // Reset timer if action is executed

        // Calculate the next current_total state
        if (i_input_coin[0] == 1) begin 
            current_total_nxt = current_total_nxt + 100;
            num_coins_nxt[0] = num_coins_nxt[0] + 1;
        end
        else if (i_input_coin[1] == 1) begin
            current_total_nxt = current_total_nxt + 500;
            num_coins_nxt[1] = num_coins_nxt[1] + 1;
        end
        else if (i_input_coin[2] == 1) begin
            current_total_nxt = current_total_nxt + 1000;
            num_coins_nxt[2] = num_coins_nxt[2] + 1;
        end
        else if (i_select_item[0] == 1) begin
            if (current_total_nxt >= 400) begin
                current_total_nxt = current_total_nxt - 400;
                withdrawl_items_nxt[0] = 1;
            end
        end
        else if (i_select_item[1] == 1) begin
            if (current_total_nxt >= 500) begin
                current_total_nxt = current_total_nxt - 500;
                withdrawl_items_nxt[1] = 1;
            end
        end
        else if (i_select_item[2] == 1) begin
            if (current_total_nxt >= 1000) begin
                current_total_nxt = current_total_nxt - 1000;
                withdrawl_items_nxt[2] = 1;
            end
        end
        else if (i_select_item[3] == 1) begin
            if (current_total_nxt >= 2000) begin
                current_total_nxt = current_total_nxt - 2000;
                withdrawl_items_nxt[3] = 1;
            end
        end
        else ResetTimer = 0;    // No action executed, do not reset timer
	end

	// Combinational logic for the outputs
	always @(*) begin
	// TODO: o_available_item
        if (current_total >= 2000) o_available_item = 4'b1111;
        else if (current_total >= 1000) o_available_item = 4'b0111;
        else if (current_total >= 500) o_available_item = 4'b0011;
        else if (current_total >= 400) o_available_item = 4'b0001;
        else o_available_item = 4'b0000;

        // TODO: o_output_item
        if (withdrawl_items[0] == 1) begin
            o_output_item[0] = 1;
        end
        else if (withdrawl_items[1] == 1) begin
            o_output_item[1] = 1;
        end
        else if (withdrawl_items[2] == 1) begin
            o_output_item[2] = 1;
        end
        else if (withdrawl_items[3] == 1) begin
            o_output_item[3] = 1;
        end
        else;

        // when return triggered, set o_return_coin signal
        if (timeout_return || i_trigger_return) begin
            if (num_coins[0]) o_return_coin[0] = 1;
            else if (num_coins[1]) o_return_coin[1] = 1;
            else if (num_coins[2]) o_return_coin[2] = 1;
            else timeout_return = 0;
        end
	end

	// Sequential circuit to reset or update the states
	always @(posedge clk) begin
		if (!reset_n) begin
			// TODO: reset all states.
            current_total <= 0;
            withdrawl_items <= 0;
            num_coins[0] <= 0;
            num_coins[1] <= 0;
            num_coins[2] <= 0;
            stopwatch <= 4'b1010;
		end
		else begin
			// TODO: update all states.
            current_total <= current_total_nxt;
            withdrawl_items <= withdrawl_items_nxt;
            num_coins[0] <= num_coins_nxt[0];
            num_coins[1] <= num_coins_nxt[1];
            num_coins[2] <= num_coins_nxt[2];
            o_output_item <= 4'b0000;   // Initialize after 1 cycle

/////////////////////////////////////////////////////////////////////////

			// decreas stopwatch
            if (ResetTimer == 0) stopwatch <= stopwatch - 4'b0001;
            else stopwatch <= 4'b1010;                

            if (stopwatch == 4'b0000) timeout_return = 1;   // Signal to Next State / Output Logic
            
			//if you have to return some coins then you have to turn on the bit
            if (timeout_return || i_trigger_return) begin
                current_total <= 0;
                withdrawl_items <= 4'b0000;
                stopwatch <= 4'b1010; // 10 cycles
            end

/////////////////////////////////////////////////////////////////////////
		end		   // update all state end
	end	   //always end

endmodule
