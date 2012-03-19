/*
 *  Copyright (c) 2009 Ondrej Dusek
 *  All rights reserved.
 * 
 *  Redistribution and use in source and binary forms, with or without modification, 
 *  are permitted provided that the following conditions are met:
 *  Redistributions of source code must retain the above copyright notice, this list 
 *  of conditions and the following disclaimer.
 *  Redistributions in binary form must reproduce the above copyright notice, this 
 *  list of conditions and the following disclaimer in the documentation and/or other 
 *  materials provided with the distribution.
 *  Neither the name of Ondrej Dusek nor the names of their contributors may be
 *  used to endorse or promote products derived from this software without specific 
 *  prior written permission.
 * 
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 *  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 *  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 *  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 *  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 *  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
 *  OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * @file Main.java The main class, reading command arguments and input.
 * @author Ondřej Dušek
 */

package lingutil.bleu;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;

/**
 * The main class, reading command arguments and input.
 */
public class Main {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {

        BleuMeasurer bm;
        BufferedReader inRef = null, inCand = null;
        boolean eof = false;
        int lineCtr = 0;

        // parameters check
	//        if ((args.length == 1) && "--".equals(args[0])) {
        
        //}
        if (args.length != 2){
            System.err.println("Input parameters: reference_file candidate_file");
            System.exit(1);
        }

        // initialization, opening the files
        bm = new BleuMeasurer();

        try {
            inRef = new BufferedReader(new FileReader(args[0]));
            inCand = new BufferedReader(new FileReader(args[1]));
        }
        catch(FileNotFoundException e){
            System.err.println(e.getMessage());
            System.exit(2);
        }

        // read sentence by sentence
        while (!eof){

            String candLine = null, refLine = null;
            String [] candTokens;
            String [] refTokens;

            try {
                refLine = inRef.readLine();
                candLine = inCand.readLine();
            }
            catch (IOException ex) {
                System.err.println(ex.getMessage());
                System.exit(1);
            }

            // test for EOF
            if (candLine == null && refLine == null){
                break;
            }
            if (candLine == null || refLine == null){
                System.err.println("The files are of different lengths.");
                System.exit(1);
            }

            // split to tokens by whitespace
            candLine.trim(); refLine.trim();
            candTokens = candLine.split("\\s+");
            refTokens = refLine.split("\\s+");

            // add sentence to stats
            bm.addSentence(refTokens, candTokens);
            if (lineCtr % 100 == 0){
                System.err.print(".");
            }
	    System.out.println("Sentence: " + lineCtr + ", score: " + bm.bleu());
	    bm.reset();
            lineCtr++;
        }

        // print the result
        //System.err.println("Total:" + lineCtr + " sentences.");
        //System.out.println("BLEU score: " + bm.bleu());
    }

}
