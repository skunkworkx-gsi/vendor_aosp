# all work is done by phh https://github.com/phhusson/treble_experimentations.git

I just wanted to make it a little easier for rom devs to start building a little faster!

# ccache doesn't work on aosp

make sure ccache is installed

aclegg2011@aclegg2011-buildbox:~/Android/gsi/aosp$ whereis ccache

ccache: /usr/local/bin/ccache

add these lines to the bottom of your .bashrc

export USE_CCACHE=1

export CCACHE_EXEC=/usr/local/bin/ccache


# inital install

mkdir android (or whatever name you want your root dir to be)

cd android

git clone https://github.com/skunkworkx-gsi/vendor_aosp.git -b q vendor/aosp

cd vendor/aosp/treble

bash first_install.sh 

# after inital install

cd ../../../

bash build_treble.sh -s (-s to sync and patch the rom)
