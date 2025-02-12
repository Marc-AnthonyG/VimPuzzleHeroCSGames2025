# How to test
- Run docker compose up
- Go to localhost:5001 and enjoy!

# Know bug
- Repair selection of ready for game
- spy on input to fail game
- display timer


# How to make a difer function
```lua
    log.info("defer_fn", roundConfig.roundTime)
    vim.defer_fn(function()
        if self.state == states.gameEnd then
            return
        end
        log.info("Deferred?", currentId, runningId)
        if currentId < runningId then
            return
        end

        self:endRound()
    end, roundConfig.roundTime)
```
