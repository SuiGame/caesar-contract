module suiGame::SUIGB {
    use std::option;
    use sui::coin;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct SUIGB has drop {}

    fun init(witness: SUIGB, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness, 
            9, 
            b"SUIGB", 
            b"SuiGameEquityPoints", 
            b"SuiGame Equity Points", 
            option::none(), 
            ctx
        );
        transfer::public_freeze_object(metadata);

        coin::mint_and_transfer(&mut treasury, 100_000_000__000_000_000, tx_context::sender(ctx), ctx);
        transfer::public_freeze_object(treasury);
    }

    #[test]
    public fun test_mint(): coin::Coin<SUIP> {
        let ctx = tx_context::dummy();

        let coin = coin::mint_for_testing<SUIP>(100_000_000__000_000_000, &mut ctx);
        assert!(coin::value(&coin) > 1, 1);
        coin
    }
}
