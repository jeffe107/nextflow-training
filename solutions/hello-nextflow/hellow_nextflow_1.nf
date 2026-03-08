#!/usr/bin/env nextflow

/*
* Use echo to print 'Hello World!' to a file
*/

process hello_world {
    output:
        path 'hello.txt'
    script:
        '''
        echo "Hello world!" > hello.txt
        '''
}

workflow {
    hello_world()

    publish:
    hello_folder = hello_world.out
}

output {
    hello_folder {
        path 'hello_folder'
    }
}