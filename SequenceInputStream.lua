
local BatchSample = require 'BatchSample'

local SequenceInputStream = {}
SequenceInputStream.__index = SequenceInputStream

function SequenceInputStream.init()
    local self = {}
    setmetatable(self, SequenceInputStream)
    
    self.total_batch_size = 0
    self.feature_size = 0
    self.maxElement_perBatch = 0
    self.maxSequence_perBatch = 0
    self.batch_num = 0
    self.batch_index = 0
    self.batch_size = 0
    self.last_incomplete_batch_size = 0
    self.mstream = nil
    self.Data = nil

    self.sparse_flag = 0 -- initalized the sparse data or dense data.

    return self
end

function SequenceInputStream:get_dimension(data_dir, fileName, opt)

    self.batch_size = opt.batch_size
    self.mstream = torch.load(path.join(data_dir, fileName))
    self.feature_size = self.mstream[-5]
    self.total_batch_size = self.mstream[-4]
    self.maxSequence_perBatch = self.mstream[-3]
    self.maxElement_perBatch = self.mstream[-2]

    local batch_size = self.mstream[-1]

    assert(batch_size == opt.batch_size, "batch_size does not match bettwen configuration and input data!")

    self.Data = BatchSample.init(batch_size, self.maxSequence_perBatch, self.maxElement_perBatch)

    self.batch_num = math.ceil(self.total_batch_size/batch_size)
    self.last_incomplete_batch_size = self.total_batch_size % batch_size
    self.batch_index = 0

end

function SequenceInputStream:init_batch()
    self.batch_index = 1 -- set the first batch
end

function SequenceInputStream:Fill(allowedFeatureDimension)
    
    if self.batch_index == self.batch_num then
        return false
    end
    self:LoadDataBatch(allowedFeatureDimension)
    self.batch_index = self.batch_index+1
    return true
end


function SequenceInputStream:LoadDataBatch(allowedFeatureDimension)
    local expectedBatchSize = self.batch_size
    if self.batch_index == (self.batch_num-1) and self.last_incomplete_batch_size ~= 0 then
        expectedBatchSize = self.last_incomplete_batch_size
    end
    if self.feature_size <= allowedFeatureDimension then
        self.Data:Load(self.mstream, expectedBatchSize)
    end



end

return SequenceInputStream