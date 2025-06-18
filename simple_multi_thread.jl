using Base.Threads
using Dates
# Import Julia's Base.Threads module, which enables multi-threading—
# running multiple threads (independent units of execution) in parallel.

# for now on differents row are differents trhreads.
# in future threads are useful with antialiasing.

#NOTE:
# julia -t 1 demo.jl   # single-thread
# julia -t 2 demo.jl   # two threads
# julia -t auto demo.jl # all available threads

"""
    simple_progress_bar(i, total; label="row", width=40)

Display a simple progress bar in the terminal.

# Arguments
- `i::Int`: Current iteration number.
- `total::Int`: Total number of iterations.
- `label::String="row"`: Description of the item being processed (e.g., "frame" for video, "row" for image).
- `width::Int=40`: Width of the progress bar in characters (default: 40).

Displays a colored progress bar with percentage and iteration count.
"""
function simple_progress_bar(i, total; label="item", width=40)
    # calculate the preogress as fraction of done/total, then calculate the % to indicate aside the bar.
    progress = i / total # the fraction o
    percent = round(progress * 100; digits = 1)

    # calculate the number of space and the number of special caracter to fill the bar.
    filled = round(Int, progress * width)
    empty = width - filled

    # To print a green block:
    # \e[32m█  → enter terminal graphics mode, set text color to green, and print the "█" character
    # \e[0m    → reset terminal style to default
    bar = repeat("\e[32m█\e[0m", filled) * repeat(" ", empty)
    print("\r[$bar] $percent% (generating $label n. $i / $total)")

    # Julia keeps output in a buffer to print multiple things at once for efficiency.
    # Not needed in this case — I want the progress bar to update in real time.
    # Forces immediate output to the terminal by flushing the output buffer.
    flush(stdout)
end


# This function creates a progress bar "listener" that updates the display 
# based on messages it receives from a Channel.
# The listener runs as an independent asynchronous task concurrently with 
# the main program and worker threads.
"""
    progress_listener(total; label="item", width=40)

Spawns an asynchronous task that listens on a channel for task completion signals and updates `simple_progress_bar`. 
    
Returns the channel object to allow external threads or tasks to send progress events.
"""
function progress_listener(total; label="item", width=40)
    count = 0
    # Instantiate a Channel{Bool} with buffer size 32.
    # Channels in Julia are thread-safe queues enabling synchronized communication
    # between producer and consumer tasks or threads.
    # This buffered channel can store up to 32 boolean values; once full, any 
    # producer trying to put! will block until space is available.
    chan = Channel{Bool}(32)

    # Launch a lightweight asynchronous task (@async) that continuously waits 
    # for messages on the channel without blocking the main thread.
    @async begin
        # Loop until the number of received completion signals equals 'total'.
        while count < total
            # take!(chan) suspends this task until a value is available in the channel.
            take!(chan)
            count += 1  # Increment the internal counter tracking completed units of work.

            # Call the progress bar rendering function with the updated count.
            simple_progress_bar(count, total; label=label, width=width)
        end
        # Ensure subsequent terminal output does not overwrite the progress bar line.
        println()
    end

    # Return the channel object so external threads or tasks can send completion notifications.
    return chan
end

# --- DEMO with time measurement and printing number of threads and elapsed time ---

# Demonstration to show multi-threaded progress updates via the listener channel.
total = 50 # total height
println("Threads used: ", Threads.nthreads())
start_time = time_ns()
# Initialize the progress listener which returns a channel to send completion events.
chan = progress_listener(total; label="row", width=40)

# Use the @threads macro to distribute the loop iterations among available CPU threads.
# Each iteration represents a unit of work performed by a thread.
@threads for i in 1:total
    # Simulate fire_all_rays!.
    sleep(0.02)

    # After completing the unit of work, the thread sends a signal (true)
    # into the channel, notifying the listener asynchronously.
    put!(chan, true)
end

sleep(0.1)

end_time = time_ns()
elapsed = end_time - start_time
println("Elapsed time: $(elapsed / 1e9) seconds")  # convert ns to seconds