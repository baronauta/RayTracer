#--- graphycs ---

"""
A simple function that prints a custom ASCII art logo and project information when using RayTracer commands or image2pfm conversion functions.
"""
function print_welcome()
    println("""
    \e[31m  _____         \e[34m _______                      
    \e[31m |  __ \\        \e[34m|__   __|                     
    \e[31m | |__) |__ _ _   _\e[34m| |_ __ __ _  ___ ___ _ __ 
    \e[31m |  _  // _` | | | \e[34m| '  __/ _` |/ __/ _ \\ '__|
    \e[31m | | \\ \\ (_| | |_| \e[34m| | | | (_| | (_|  __/ |   
    \e[31m |_|  \\_\\__,_|\\__, \e[34m|_|_|  \\__,_|\\___\\___|_|   
    \e[31m               __/ |                          
    \e[31m              |___/                           \e[0m
    \e[1;32mAuthors:\e[0m Andrea Baroffio, Stefano Bozzi
    \e[1;36mGitHub: \e[4mhttps://github.com/baronauta/RayTracer \e[0m
    """)
end